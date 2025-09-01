package com.example.attendance.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import com.example.attendance.dao.AttendanceDAO;
import com.example.attendance.dto.Attendance;
import com.example.attendance.dto.User;

@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {
    private final AttendanceDAO attendanceDAO = new AttendanceDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        User user = (User) session.getAttribute("user");

        // セッションにsuccessMessageがあればリクエストスコープにセット
        String message = (String) session.getAttribute("successMessage");
        if (message != null) {
            req.setAttribute("successMessage", message);
            session.removeAttribute("successMessage");
        }

        String action = req.getParameter("action");

        if ("export_csv".equals(action) && "admin".equals(user.getRole())) {
            exportCsv(req, resp);
        } else if ("filter".equals(action) && "admin".equals(user.getRole())) {
            handleAdminFilter(req, resp);
        } else {
            if ("admin".equals(user.getRole())) {
                handleAdminView(req, resp);
            } else {
                handleEmployeeView(req, resp, user);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        User user = (User) session.getAttribute("user");
        String action = req.getParameter("action");

        try {
            switch (action) {
                case "check_in" -> {
                    attendanceDAO.checkIn(user.getUsername());
                    session.setAttribute("successMessage", "出勤を記録しました。");
                }
                case "check_out" -> {
                    attendanceDAO.checkOut(user.getUsername());
                    session.setAttribute("successMessage", "退勤を記録しました。");
                }
                case "add_manual" -> handleAddManual(req, session, user);
                case "update_manual" -> handleUpdateManual(req, session, user);
                case "delete_manual" -> handleDeleteManual(req, session, user);
            }
        } catch (DateTimeParseException e) {
            session.setAttribute("errorMessage", "日付/時刻の形式が不正です。");
        }

        // リダイレクト
        if ("admin".equals(user.getRole())) {
            String filterUserId = req.getParameter("filterUserId") != null ? req.getParameter("filterUserId") : "";
            String startDate = req.getParameter("startDate") != null ? req.getParameter("startDate") : "";
            String endDate = req.getParameter("endDate") != null ? req.getParameter("endDate") : "";
            resp.sendRedirect("attendance?action=filter&filterUserId=" + filterUserId +
                    "&startDate=" + startDate + "&endDate=" + endDate);
        } else {
            resp.sendRedirect("attendance");
        }
    }

    // --------------------- ヘルパーメソッド ---------------------

    private void handleAdminFilter(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String filterUserId = req.getParameter("filterUserId");
        LocalDate startDate = parseLocalDate(req.getParameter("startDate"));
        LocalDate endDate = parseLocalDate(req.getParameter("endDate"));

        List<Attendance> filteredRecords = attendanceDAO.findFilteredRecords(filterUserId, startDate, endDate);
        req.setAttribute("allAttendanceRecords", filteredRecords);

        Map<String, Long> totalHoursByUser = filteredRecords.stream()
                .collect(Collectors.groupingBy(Attendance::getUserId,
                        Collectors.summingLong(att -> {
                            if (att.getCheckInTime() != null && att.getCheckOutTime() != null) {
                                return java.time.temporal.ChronoUnit.HOURS.between(att.getCheckInTime(), att.getCheckOutTime());
                            }
                            return 0L;
                        })));

        req.setAttribute("totalHoursByUser", totalHoursByUser);
        req.setAttribute("monthlyWorkingHours", attendanceDAO.getMonthlyWorkingHours(filterUserId));
        req.setAttribute("monthlyCheckInCounts", attendanceDAO.getMonthlyCheckInCounts(filterUserId));

        RequestDispatcher rd = req.getRequestDispatcher("/jsp/admin_menu.jsp");
        rd.forward(req, resp);
    }

    private void handleAdminView(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        List<Attendance> allRecords = attendanceDAO.findAll();
        req.setAttribute("allAttendanceRecords", allRecords);

        Map<String, Long> totalHoursByUser = allRecords.stream()
                .collect(Collectors.groupingBy(Attendance::getUserId,
                        Collectors.summingLong(att -> {
                            if (att.getCheckInTime() != null && att.getCheckOutTime() != null) {
                                return java.time.temporal.ChronoUnit.HOURS.between(att.getCheckInTime(), att.getCheckOutTime());
                            }
                            return 0L;
                        })));
        req.setAttribute("totalHoursByUser", totalHoursByUser);
        req.setAttribute("monthlyWorkingHours", attendanceDAO.getMonthlyWorkingHours(null));
        req.setAttribute("monthlyCheckInCounts", attendanceDAO.getMonthlyCheckInCounts(null));

        RequestDispatcher rd = req.getRequestDispatcher("/jsp/admin_menu.jsp");
        rd.forward(req, resp);
    }

    private void handleEmployeeView(HttpServletRequest req, HttpServletResponse resp, User user) throws ServletException, IOException {
        List<Attendance> records = attendanceDAO.findByUserId(user.getUsername());
        req.setAttribute("attendanceRecords", records);

        // ---------------- アラート機能追加 ----------------
        Map<String, String> alerts = records.stream().flatMap(att -> {
            java.util.List<java.util.AbstractMap.SimpleEntry<String,String>> temp = new java.util.ArrayList<>();

            if (att.getCheckInTime() != null && 
                (att.getCheckInTime().getHour() > 9 || (att.getCheckInTime().getHour() == 9 && att.getCheckInTime().getMinute() > 15))) {
                temp.add(new java.util.AbstractMap.SimpleEntry<>(att.getCheckInTime().toString(), "遅刻"));
            }
            if (att.getCheckOutTime() != null && att.getCheckOutTime().getHour() < 17) {
                temp.add(new java.util.AbstractMap.SimpleEntry<>(att.getCheckOutTime().toString(), "早退"));
            }
            if (att.getCheckInTime() != null && att.getCheckOutTime() != null) {
                long hours = java.time.temporal.ChronoUnit.HOURS.between(att.getCheckInTime(), att.getCheckOutTime());
                if (hours > 8) {
                    temp.add(new java.util.AbstractMap.SimpleEntry<>(att.getCheckOutTime().toString(), "残業"));
                }
            }
            return temp.stream();
        }).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

        req.setAttribute("attendanceAlerts", alerts);
        // -------------------------------------------------

        RequestDispatcher rd = req.getRequestDispatcher("/jsp/employee_menu.jsp");
        rd.forward(req, resp);
    }

    private void handleAddManual(HttpServletRequest req, HttpSession session, User user) {
        if (!"admin".equals(user.getRole())) return;

        String userId = req.getParameter("userId");
        LocalDateTime checkIn = LocalDateTime.parse(req.getParameter("checkInTime"));
        String checkOutStr = req.getParameter("checkOutTime");
        LocalDateTime checkOut = (checkOutStr != null && !checkOutStr.isEmpty()) ? LocalDateTime.parse(checkOutStr) : null;

        attendanceDAO.addManualAttendance(userId, checkIn, checkOut);
        session.setAttribute("successMessage", "勤怠記録を手動で追加しました。");
    }

    private void handleUpdateManual(HttpServletRequest req, HttpSession session, User user) {
        if (!"admin".equals(user.getRole())) return;

        String userId = req.getParameter("userId");
        LocalDateTime oldCheckIn = LocalDateTime.parse(req.getParameter("oldCheckInTime"));
        String oldCheckOutStr = req.getParameter("oldCheckOutTime");
        LocalDateTime oldCheckOut = (oldCheckOutStr != null && !oldCheckOutStr.isEmpty()) ? LocalDateTime.parse(oldCheckOutStr) : null;
        LocalDateTime newCheckIn = LocalDateTime.parse(req.getParameter("newCheckInTime"));
        String newCheckOutStr = req.getParameter("newCheckOutTime");
        LocalDateTime newCheckOut = (newCheckOutStr != null && !newCheckOutStr.isEmpty()) ? LocalDateTime.parse(newCheckOutStr) : null;

        if (!attendanceDAO.updateManualAttendance(userId, oldCheckIn, oldCheckOut, newCheckIn, newCheckOut)) {
            session.setAttribute("errorMessage", "勤怠記録の更新に失敗しました。");
        } else {
            session.setAttribute("successMessage", "勤怠記録を手動で更新しました。");
        }
    }

    private void handleDeleteManual(HttpServletRequest req, HttpSession session, User user) {
        if (!"admin".equals(user.getRole())) return;

        String userId = req.getParameter("userId");
        LocalDateTime checkIn = LocalDateTime.parse(req.getParameter("checkInTime"));
        String checkOutStr = req.getParameter("checkOutTime");
        LocalDateTime checkOut = (checkOutStr != null && !checkOutStr.isEmpty()) ? LocalDateTime.parse(checkOutStr) : null;

        if (!attendanceDAO.deleteManualAttendance(userId, checkIn, checkOut)) {
            session.setAttribute("errorMessage", "勤怠記録の削除に失敗しました。");
        } else {
            session.setAttribute("successMessage", "勤怠記録を削除しました。");
        }
    }

    private LocalDate parseLocalDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) return null;
        try {
            return LocalDate.parse(dateStr);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private void exportCsv(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment;filename=\"attendance_records.csv\"");
        PrintWriter writer = resp.getWriter();

        writer.append("User ID,Check-in Time,Check-out Time\n");
        String filterUserId = req.getParameter("filterUserId");
        LocalDate startDate = parseLocalDate(req.getParameter("startDate"));
        LocalDate endDate = parseLocalDate(req.getParameter("endDate"));

        List<Attendance> records = attendanceDAO.findFilteredRecords(filterUserId, startDate, endDate);
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        for (Attendance record : records) {
            writer.append(String.format("%s,%s,%s\n",
                    record.getUserId(),
                    record.getCheckInTime() != null ? record.getCheckInTime().format(formatter) : "",
                    record.getCheckOutTime() != null ? record.getCheckOutTime().format(formatter) : ""));
        }
        writer.flush();
    }
}
