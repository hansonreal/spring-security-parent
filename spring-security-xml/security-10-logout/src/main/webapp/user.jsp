<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>这是用户界面</title>
</head>
<body>
    本页面需要有“ROLE_USER”角色才可以访问
    <span>
    <a href="${pageContext.request.contextPath}/logout.do">退出</a>
</span>
</body>
</html>
