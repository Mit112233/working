<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>週別勤務時間</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
	<h1>週別勤務時間</h1>
	<canvas id="weeklyChart"></canvas>
	<script>
const labels = [
    <c:forEach var="entry" items="${weeklyHours}" varStatus="loop">
        '${entry.key}'<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
];
const data = [
    <c:forEach var="entry" items="${weeklyHours}" varStatus="loop">
        ${entry.value}<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
];
new Chart(document.getElementById('weeklyChart').getContext('2d'), {
    type: 'bar',
    data: { labels: labels, datasets: [{ label: '勤務時間(時間)', data: data, backgroundColor: 'rgba(75,192,192,0.5)', borderColor: 'rgba(75,192,192,1)', borderWidth: 1 }] },
    options: { scales: { y: { beginAtZero: true } } }
});
</script>
	<a
		href="${pageContext.request.contextPath}/attendance?action=admin_menu">管理メニューに戻る</a>
</body>
</html>
