# 1、入门程序
首先为Spring Security专门建立一个Spring的配置文件，该文件就专门用来作为Spring Security的配置。
使用Spring Security需要引入Spring Security的NameSpace。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:security="http://www.springframework.org/schema/security"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
          http://www.springframework.org/schema/beans/spring-beans.xsd
          http://www.springframework.org/schema/security
          http://www.springframework.org/schema/security/spring-security.xsd">
</beans>
```

Spring Security命名空间的引入可以简化我们的开发，它涵盖了大部分Spring Security常用的功能。它的设计是基于框架内大范围的依赖的，可以被划分为以下几块：

1. Web/Http 安全：这是最复杂的部分。通过建立filter和相关的service bean来实现框架的认证机制。当访问受保护的URL时会将用户引入登录界面或者是错误提示界面
2. 业务对象或者方法的安全：控制方法访问权限的
3. AuthenticationManager：处理来自于框架其他部分的认证请求
4. AccessDecisionManager：为Web或方法的安全提供访问决策。会注册一个默认的，但是我们也可以通过普通bean注册的方式使用自定义的AccessDecisionManager
5. AuthenticationProvider：AuthenticationManager是通过它来认证用户的
6. UserDetailsService：跟AuthenticationProvider关系密切，用来获取用户信息的。

