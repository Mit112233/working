<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<title>管理者メニュー</title>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/css/style.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
	<div class="container">
		<h1>管理者メニュー</h1>
		<p>ようこそ, ${user.username}さん (管理者)</p>
		<div class="main-nav">
			<a href="attendance?action=filter">勤怠履歴管理</a> <a
				href="users?action=list">ユーザー管理</a> <a
				href="${pageContext.request.contextPath}/logout">ログアウト</a>
		</div>

		<c:if test="${not empty sessionScope.successMessage}">
			<p class="success-message">
				<c:out value="${sessionScope.successMessage}" />
			</p>
			<c:remove var="successMessage" scope="session" />
		</c:if>

		<!-- フィルタ検索 -->
		<h2>勤怠履歴</h2>
		<form action="attendance" method="get" class="filter-form">
			<input type="hidden" name="action" value="filter">
			<div>
				<label for="filterUserId">ユーザーID:</label> <input type="text"
					id="filterUserId" name="filterUserId"
					value="<c:out value='${param.filterUserId}'/>">
			</div>
			<div>
				<label for="startDate">開始日:</label> <input type="date"
					id="startDate" name="startDate"
					value="<c:out value='${param.startDate}'/>">
			</div>
			<div>
				<label for="endDate">終了日:</label> <input type="date" id="endDate"
					name="endDate" value="<c:out value='${param.endDate}'/>">
			</div>
			<button type="submit" class="button">フィルタ</button>
		</form>

		<p class="error-message">
			<c:out value="${errorMessage}" />
		</p>

		<a
			href="attendance?action=export_csv&filterUserId=<c:out value='${param.filterUserId}'/>&startDate=<c:out value='${param.startDate}'/>&endDate=<c:out value='${param.endDate}'/>"
			class="button">勤怠履歴を CSV エクスポート</a>

		<!-- 勤怠サマリー -->
		<h3>勤怠サマリー (合計労働時間)</h3>
		<table class="summary-table">
			<thead>
				<tr>
					<th>ユーザーID</th>
					<th>合計労働時間 (時間)</th>
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
					<tr>
						<td colspan="2">データがありません。</td>
					</tr>
				</c:if>
			</tbody>
		</table>

		<!-- グラフ表示 -->
		<h3>勤怠グラフ</h3>
		<h4>日別勤務時間</h4>
		<canvas id="dailyChart"></canvas>

		<h4>週別勤務時間</h4>
		<canvas id="weeklyChart"></canvas>

		<h4>月別勤務時間</h4>
		<canvas id="monthlyChart"></canvas>

		<script>
			// 日別
			const dailyLabels = [
				<c:forEach var="entry" items="${dailyHours}" varStatus="loop">
					'${entry.key}'<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			const dailyData = [
				<c:forEach var="entry" items="${dailyHours}" varStatus="loop">
					${entry.value}<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			new Chart(document.getElementById("dailyChart").getContext("2d"), {
				type: 'line',
				data: { labels: dailyLabels, datasets: [{ label: '勤務時間(時間)', data: dailyData, borderColor: 'red', fill: false }] },
				options: { responsive: true, scales: { y: { beginAtZero: true } } }
			});

			// 週別
			const weeklyLabels = [
				<c:forEach var="entry" items="${weeklyHours}" varStatus="loop">
					'${entry.key}'<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			const weeklyData = [
				<c:forEach var="entry" items="${weeklyHours}" varStatus="loop">
					${entry.value}<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			new Chart(document.getElementById("weeklyChart").getContext("2d"), {
				type: 'bar',
				data: { labels: weeklyLabels, datasets: [{ label: '勤務時間(時間)', data: weeklyData, backgroundColor: 'rgba(75,192,192,0.5)', borderColor: 'rgba(75,192,192,1)', borderWidth: 1 }] },
				options: { responsive: true, scales: { y: { beginAtZero: true } } }
			});

			// 月別
			const monthlyLabels = [
				<c:forEach var="entry" items="${monthlyHours}" varStatus="loop">
					'${entry.key}'<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			const monthlyData = [
				<c:forEach var="entry" items="${monthlyHours}" varStatus="loop">
					${entry.value}<c:if test="${!loop.last}">,</c:if>
				</c:forEach>
			];
			new Chart(document.getElementById("monthlyChart").getContext("2d"), {
				type: 'bar',
				data: { labels: monthlyLabels, datasets: [{ label: '勤務時間(時間)', data: monthlyData, backgroundColor: 'rgba(54,162,235,0.5)', borderColor: 'rgba(54,162,235,1)', borderWidth: 1 }] },
				options: { responsive: true, scales: { y: { beginAtZero: true } } }
			});
		</script>

		<!-- 詳細勤怠履歴 -->
		<h3>詳細勤怠履歴</h3>
		<table>
			<thead>
				<tr>
					<th>従業員 ID</th>
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
						<td class="table-actions">
							<form action="attendance" method="post" style="display: inline;">
								<input type="hidden" name="action" value="delete_manual">
								<input type="hidden" name="userId" value="${att.userId}">
								<input type="hidden" name="checkInTime"
									value="${att.checkInTime}"> <input type="hidden"
									name="checkOutTime" value="${att.checkOutTime}"> <input
									type="submit" value="削除" class="button danger"
									onclick="return confirm('本当にこの勤怠記録を削除しますか？');">
							</form>
						</td>
					</tr>
				</c:forEach>
				<c:if test="${empty allAttendanceRecords}">
					<tr>
						<td colspan="4">データがありません。</td>
					</tr>
				</c:if>
			</tbody>
		</table>

		<!-- 勤怠記録の手動追加 -->
		<h2>勤怠記録の手動追加</h2>
		<form action="attendance" method="post">
			<input type="hidden" name="action" value="add_manual">
			<p>
				<label for="manualUserId">ユーザーID:</label> <input type="text"
					id="manualUserId" name="userId" required>
			</p>
			<p>
				<label for="manualCheckInTime">出勤時刻:</label> <input
					type="datetime-local" id="manualCheckInTime" name="checkInTime"
					required>
			</p>
			<p>
				<label for="manualCheckOutTime">退勤時刻 (任意):</label> <input
					type="datetime-local" id="manualCheckOutTime" name="checkOutTime">
			</p>
			<div class="button-group">
				<input type="submit" value="追加">
			</div>
		</form>
	</div>
</body>
</html>