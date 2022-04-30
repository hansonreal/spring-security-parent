[TOC]

# 1、Spring Security Filter

> Spring Security的底层是通过一系列的Filter来管理的，每个Filter都有其自身的功能，而且各个Filter在功能上还有关联关系，所以它们的顺序也是非常重要的。

## 1.1、Filter顺序

 Spring Security已经定义了一些Filter，不管实际应用中你用到了哪些，它们应当保持如下顺序：

- `ChannelProcessingFilter`：如果你访问的channel错了，那首先就会在channel之间进行跳转，如http变为https。
- `SecurityContextPersistenceFilter`：该过滤器只会在每次请求之前执行一次，一旦请求进来的时候就可以在SecurityContextHolder中建立一个SecurityContext，然后在请求结束的时候，任何对SecurityContext的改变都可以被copy到HttpSession。
- `ConcurrentSessionFilter`：因为它需要使用SecurityContextHolder的功能，而且更新对应session的最后更新时间，以及通过SessionRegistry获取当前的SessionInformation以检查当前的session是否已经过期，过期则会调用LogoutHandler。
- 认证处理机制，如UsernamePasswordAuthenticationFilter，CasAuthenticationFilter，BasicAuthenticationFilter等，以便于SecurityContextHolder可以被更新为包含一个有效的Authentication请求。
- `SecurityContextHolderAwareRequestFilter`：将会把HttpServletRequest封装成一个继承自HttpServletRequestWrapper的SecurityContextHolderAwareRequestWrapper，同时使用SecurityContext实现了HttpServletRequest中与安全相关的方法。
- `JaasApiIntegrationFilter`：如果SecurityContextHolder中拥有的Authentication是一个JaasAuthenticationToken，那么该Filter将使用包含在JaasAuthenticationToken中的Subject继续执行FilterChain。
- `RememberMeAuthenticationFilter`：如果之前的认证处理机制没有更新SecurityContextHolder，并且用户请求包含了一个Remember-Me对应的cookie，那么一个对应的Authentication将会设给SecurityContextHolder。
- `AnonymousAuthenticationFilter`：如果之前的认证机制都没有更新SecurityContextHolder拥有的Authentication，那么一个AnonymousAuthenticationToken将会设给SecurityContextHolder。
- `ExceptionTransactionFilter`：用于处理在FilterChain范围内抛出的AccessDeniedException和AuthenticationException，并把它们转换为对应的Http错误码返回或者对应的页面。
- `FilterSecurityInterceptor`：保护Web URI，并且在访问被拒绝时抛出异常。

## 1.2、添加Filter到FilterChain

基于XML配置Spring Security时，Spring Security会自动为开发者建立对应的FilterChain以及其中的Filter。但是有时候我们需要添加自定义Filter到FilterChain中，又或者是因为某些特性需要自己显示的定义Spring Security已经为我们提供好的Filter，然后再把它们添加到FilterChain。

通过http元素下的`custom-filter`元素来定义自定义的Filter：

```xml
<security:http auto-config="true">
    <security:form-login login-page="/login.jsp" login-processing-url="/login.do"
                         username-parameter="username"
                         password-parameter="password"
                         default-target-url="/index.jsp"
                         authentication-failure-url="/failure.jsp"
                         always-use-default-target="true"/>
    <security:intercept-url pattern="/login.jsp" access="ROLE_ANONYMOUS"/>
    <security:intercept-url pattern="/user.jsp" access="ROLE_USER"/>
    <security:intercept-url pattern="/admin.jsp" access="ROLE_ADMIN"/>
    <security:custom-filter ref="" after="" before="" position=""/>// 配置自定义Filter
</security:http>
```

定义`custom-filter`时需要我们通过ref属性指定其对应关联的是哪个Filter，此外还需要通过position、before或者after指定该Filter放置的位置。

Spring Security对`FilterChain`中Filter顺序是有严格的规定的。Spring Security对那些内置的Filter都指定了一个别名，同时指定了它们的位置。我们在定义custom-filter的position、before和after时使用的值就是对应着这些别名所处的位置。如`position="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER对应的那个位置，`before="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER之前，`after="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER之后。此外还有两个特殊的位置可以指定，FIRST和LAST，分别对应第一个和最后一个Filter，如你想把定义好的Filter放在最后，则可以使用`after="LAST"`。

Spring Security给我们定义好的FilterChain中Filter对应的位置顺序、它们的别名以及将触发自动添加到FilterChain的元素或属性定义。下面的定义是按顺序的：

| 别名                         | Filter类                                        | 对应元素或属性                              |
| :--------------------------- | :---------------------------------------------- | ------------------------------------------- |
| CHANNEL_FILTER               | `ChannelProcessingFilter`                       | http>intercept-url>requires-channel         |
| SECURITY_CONTEXT_FILTER      | `SecurityContextPersistenceFilter`              | http                                        |
| CONCURRENT_SESSION_FILTER    | `ConcurrentSessionFilter`                       | http>session-management>concurrency-control |
| LOGOUT_FILTER                | `LogoutFilter`                                  | http>logout                                 |
| X509_FILTER                  | `X509AuthenticationFilter`                      | http>x509                                   |
| PRE_AUTH_FILTER              | `AstractPreAuthenticatedProcessingFilter`的子类 | N/A                                         |
| CAS_FILTER                   | `CasAuthenticationFilter`                       | N/A                                         |
| FORM_LOGIN_FILTER            | `UsernamePasswordAuthenticationFilter`          | http>form-login                             |
| BASIC_AUTH_FILTER            | `BasicAuthenticationFilter`                     | http>http-basic                             |
| SERVLET_API_SUPPORT_FILTER   | `SecurityContextHolderAwareRequestFilter`       | http>servlet-api-provision                  |
| JAAS_API_SUPPORT_FILTER      | `JaasApiIntegrationFilter`                      | http>jaas-api-provision                     |
| REMEMBER_ME_FILTER           | `RememberMeAuthenticationFilter`                | http>remember-me                            |
| ANONYMOUS_FILTER             | `AnonymousAuthenticationFilter`                 | http>anonymous                              |
| SESSION_MANAGEMENT_FILTER    | `SessionManagementFilter`                       | http>session-management                     |
| EXCEPTION_TRANSLATION_FILTER | `ExceptionTranslationFilter`                    | http                                        |
| FILTER_SECURITY_INTERCEPTOR  | `FilterSecurityInterceptor`                     | http                                        |
| SWITCH_USER_FILTER           | `SwitchUserFilter`                              | N/A                                         |



## 1.3、DelegatingFilterProxy

## 1.4、FilterChainProxy

## 1.5、Spring Security内置核心的Filter

### 1.5.1、FilterSecurityInterceptor

### 1.5.2、ExceptionTranslationFilter

### 1.5.3、SecurityContextPersistenceFilter

### 1.5.4、UsernamePasswordAuthenticationFilter

