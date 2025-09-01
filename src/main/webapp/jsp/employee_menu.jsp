<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>従業員メニュー</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body>
<div class="container">
    <h1>従業員メニュー</h1>
    <p>ようこそ, ${sessionScope.user.username} さん</p>

    <!-- 成功・エラーメッセージ -->
    <c:if test="${not empty sessionScope.successMessage}">
        <p class="success-message">${sessionScope.successMessage}</p>
        <c:remove var="successMessage" scope="session" />
    </c:if>
    <c:if test="${not empty sessionScope.errorMessage}">
        <p class="error-message">${sessionScope.errorMessage}</p>
        <c:remove var="errorMessage" scope="session" />
    </c:if>

    <!-- 出勤・退勤ボタン -->
    <div class="button-group">
        <form action="${pageContext.request.contextPath}/attendance" method="post" style="display:inline;">
            <input type="hidden" name="action" value="check_in">
            <input type="submit" class="button check-in" value="出勤">
        </form>
        <form action="${pageContext.request.contextPath}/attendance" method="post" style="display:inline;">
            <input type="hidden" name="action" value="check_out">
            <input type="submit" class="button check-out" value="退勤">
        </form>
    </div>

    <!-- 勤怠記録 -->
    <h2>あなたの勤怠履歴</h2>
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>出勤時刻</th>
                    <th>退勤時刻</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="att" items="${attendanceRecords}">
                    <tr>
                        <td>${att.checkInTime}</td>
                        <td>${att.checkOutTime}</td>
                    </tr>
                </c:forEach>
                <c:if test="${empty attendanceRecords}">
                    <tr><td colspan="2">勤怠記録がありません。</td></tr>
                </c:if>
            </tbody>
        </table>
    </div>

    <!-- 勤務時間アラート -->
    <c:if test="${not empty attendanceAlerts}">
        <h2>勤務時間アラート</h2>
        <div class="alert-container">
            <c:forEach var="entry" items="${attendanceAlerts}">
                <div class="alert-message
                    <c:choose>
                        <c:when test="${entry.key == 'late'}"> alert-late</c:when>
                        <c:when test="${entry.key == 'early'}"> alert-early</c:when>
                        <c:when test="${entry.key == 'overtime'}"> alert-overtime</c:when>
                    </c:choose>">
                    ${entry.value}（${entry.key}）
                </div>
            </c:forEach>
        </div>
    </c:if>

    <!-- ログアウト -->
    <div class="button-group">
        <a href="${pageContext.request.contextPath}/logout" class="button secondary">ログアウト</a>
    </div>
</div>
</body>
</html>
