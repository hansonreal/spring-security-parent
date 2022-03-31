<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>认证提供程序</title>
</head>
<body>
This is home page!

<br>
<span>
        <a href="${pageContext.request.contextPath}/user.jsp">ROLE_USER权限测试</a>
        <br>
        <a href="${pageContext.request.contextPath}/admin.jsp">ADMIN_USER权限测试</a>
    </span>
</body>
</html>
