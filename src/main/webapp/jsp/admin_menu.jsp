<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理者メニュー</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body>
<div class="container">
    <h1>管理者メニュー</h1>
    <p>ようこそ, ${sessionScope.user.username} さん (管理者)</p>

    <c:if test="${not empty sessionScope.successMessage}">
        <p class="success-message">${sessionScope.successMessage}</p>
        <c:remove var="successMessage" scope="session"/>
    </c:if>

    <div class="main-nav">
        <a href="${pageContext.request.contextPath}/attendance?action=filter">勤怠履歴管理</a>
        <a href="${pageContext.request.contextPath}/users?action=list">ユーザー管理</a>
        <a href="${pageContext.request.contextPath}/logout">ログアウト</a>
    </div>

    <h3>勤怠サマリー</h3>
    <table>
        <thead>
            <tr>
                <th>ユーザーID</th>
                <th>合計労働時間</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach var="entry" items="${totalHoursByUser}">
                <tr>
                    <td>${entry.key}</td>
                    <td>${entry.value}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty totalHoursByUser}">
                <tr><td colspan="2">データがありません</td></tr>
            </c:if>
        </tbody>
    </table>

    <h3>詳細勤怠履歴</h3>
    <table>
        <thead>
            <tr>
                <th>ユーザーID</th>
                <th>出勤時刻</th>
                <th>退勤時刻</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach var="att" items="${allAttendanceRecords}">
                <tr>
                    <td>${att.userId}</td>
                    <td>${att.checkInTime}</td>
                    <td>${att.checkOutTime}</td>
                    <td>
                        <form action="${pageContext.request.contextPath}/attendance" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="delete_manual">
                            <input type="hidden" name="userId" value="${att.userId}">
                            <input type="hidden" name="checkInTime" value="${att.checkInTime}">
                            <input type="hidden" name="checkOutTime" value="${att.checkOutTime}">
                            <input type="submit" value="削除" class="button danger"
                                   onclick="return confirm('本当に削除しますか？');">
                        </form>
                    </td>
                </tr>
            </c:forEach>
            <c:if test="${empty allAttendanceRecords}">
                <tr><td colspan="4">データがありません</td></tr>
            </c:if>
        </tbody>
    </table>
</div>
</body>
</html>