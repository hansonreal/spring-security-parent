[TOC]

# 1、Spring Security 退出登录Logout

要实现退出登录的功能我们需要在http元素下定义logout元素，这样Spring Security将自动为我们添加用于处理退出登录的过滤器`LogoutFilter`到`SecurityFilterChain`。

当我们指定了http元素的`auto-config`属性为`true`时logout定义是会自动配置的，此时我们默认退出登录的URL为`/j_spring_security_logout`，可以通过logout元素的`logout-url`属性来改变退出登录的默认地址。

```xml
<security:authentication-manager id="authenticationManager">
    <security:authentication-provider>
        <security:user-service>
            <security:user name="admin" password="admin" authorities="ROLE_ADMIN,ROLE_USER"/>
            <security:user name="user" password="user" authorities="ROLE_USER"/>
        </security:user-service>
    </security:authentication-provider>
</security:authentication-manager>

<security:http pattern="login.jsp" security="none"/>
<security:http auto-config="true" authentication-manager-ref="authenticationManager">
    <security:form-login login-page="/login.jsp" login-processing-url="/login.do"
                         username-parameter="username"
                         password-parameter="password"
                         default-target-url="/index.jsp"
                         authentication-failure-url="/failure.jsp"
                         always-use-default-target="true"/>
    <security:intercept-url pattern="/login.jsp" access="ROLE_ANONYMOUS"/>
    <security:intercept-url pattern="/user.jsp" access="ROLE_USER"/>
    <security:intercept-url pattern="/admin.jsp" access="ROLE_ADMIN"/>
    <security:logout logout-url="/logout.do"/> //自定义退出配置
</security:http>
```

此外，我们还可以给logout指定如下属性：

| 属性名                | 说明                                                         |
| --------------------- | ------------------------------------------------------------ |
| `invalidate-session`  | 表示是否要在退出登录后让当前session失效，默认为true。        |
| `delete-cookies`      | 指定退出登录后需要删除的cookie名称，多个cookie之间以逗号分隔。 |
| `logout-success-url`  | 指定成功退出登录后要重定向的URL。需要注意的是对应的URL应当是不需要登录就可以访问的。 |
| `success-handler-ref` | 指定用来处理成功退出登录的LogoutSuccessHandler的引用。       |

