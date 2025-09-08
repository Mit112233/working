<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>日別勤務時間</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
	<h1>日別勤務時間</h1>
	<canvas id="dailyChart"></canvas>
	<script>
const labels = [
    <c:forEach var="entry" items="${dailyHours}" varStatus="loop">
        '${entry.key}'<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
];
const data = [
    <c:forEach var="entry" items="${dailyHours}" varStatus="loop">
        ${entry.value}<c:if test="${!loop.last}">,</c:if>
    </c:forEach>
];
new Chart(document.getElementById('dailyChart').getContext('2d'), {
    type: 'line',
    data: { labels: labels, datasets: [{ label: '勤務時間(時間)', data: data, borderColor: 'rgba(255,99,132,1)', fill: false }] },
    options: { scales: { y: { beginAtZero: true } } }
});
</script>
	<a
		href="${pageContext.request.contextPath}/attendance?action=admin_menu">管理メニューに戻る</a>
</body>
</html>
