# 1、基于XML版本
> Spring 版本为3.2.6.RELEASE
## 1.1、入门程序
- 添加Maven依赖,参考[Maven配置](./spring-security-xml/security-01-helloworld/pom.xml)
- 引入Spring Security的[命名空间](./spring-security-xml/security-01-helloworld/src/main/resources/application-security.xml)
    - Spring Security的命名空间，用于简化开发，它涵盖了大部分Spring Security常用的功能。它的设计是基于框架内大范围的依赖的，可以被划分为以下几块：
        - Web/Http 安全：通过建立filter和相关的service bean来实现框架的认证机制。当访问受保护的URL时会将用户引入登录界面或者是错误提示界面
        - 业务对象或者方法的安全：控制方法级别的访问控制
        - AuthenticationManager：认证管理器，负责证明谁可以登录
        - AccessDecisionManager：为Web或方法的安全提供访问决策。会注册一个默认的，但是也可以通过普通bean注册的方式使用自定义的AccessDecisionManager。
        - AuthenticationProvider：AuthenticationManager是通过它来认证用户的
        - UserDetailsService：跟AuthenticationProvider关系密切，用来获取用户信息的