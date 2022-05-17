[TOC]

# 1、Spring Security Filter

> Spring Security的底层是通过一系列的Filter来管理的，每个Filter都有其自身的功能，而且各个Filter在功能上还有关联关系，所以它们的顺序也是非常重要的。

## 1.1、Filter顺序

 Spring Security已经定义了一些Filter，不管实际应用中你用到了哪些，它们应当保持如下顺序：

- 1、`ChannelProcessingFilter`：如果你访问的channel错了，那首先就会在channel之间进行跳转，如http变为https。
- 2、`SecurityContextPersistenceFilter`：该过滤器只会在每次请求之前执行一次，一旦请求进来的时候就可以在SecurityContextHolder中建立一个SecurityContext，然后在请求结束的时候，任何对SecurityContext的改变都可以被copy到HttpSession。
- 3、`ConcurrentSessionFilter`：因为它需要使用SecurityContextHolder的功能，而且更新对应session的最后更新时间，以及通过SessionRegistry获取当前的SessionInformation以检查当前的session是否已经过期，过期则会调用LogoutHandler。
- 4、认证处理机制，如UsernamePasswordAuthenticationFilter，CasAuthenticationFilter，BasicAuthenticationFilter等，以便于SecurityContextHolder可以被更新为包含一个有效的Authentication请求。
- 5、`SecurityContextHolderAwareRequestFilter`：将会把HttpServletRequest封装成一个继承自HttpServletRequestWrapper的SecurityContextHolderAwareRequestWrapper，同时使用SecurityContext实现了HttpServletRequest中与安全相关的方法。
- 6、`JaasApiIntegrationFilter`：如果SecurityContextHolder中拥有的Authentication是一个JaasAuthenticationToken，那么该Filter将使用包含在JaasAuthenticationToken中的Subject继续执行FilterChain。
- 7、`RememberMeAuthenticationFilter`：如果之前的认证处理机制没有更新SecurityContextHolder，并且用户请求包含了一个Remember-Me对应的cookie，那么一个对应的Authentication将会设给SecurityContextHolder。
- 8、`AnonymousAuthenticationFilter`：如果之前的认证机制都没有更新SecurityContextHolder拥有的Authentication，那么一个AnonymousAuthenticationToken将会设置给SecurityContextHolder。
- 9、`ExceptionTransactionFilter`：用于处理在FilterChain范围内抛出的AccessDeniedException和AuthenticationException，并把它们转换为对应的Http错误码返回或者对应的页面。
- 10、`FilterSecurityInterceptor`：保护Web URI，并且在访问被拒绝时抛出异常。

## 1.2、添加Filter到FilterChain

当我们基于XML配置Spring Security时，Spring Security会自动为我们建立对应的FilterChain以及其中的Filter。但是有时候我们需要添加自定义Filter到FilterChain中，又或者是因为某些特性需要自己显示的定义Spring Security已经为我们提供好的Filter，然后再把它们添加到FilterChain。

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

定义`custom-filter`时需要我们通过ref属性指定其对应关联的是哪个Filter，此外还需要通过**position**、**before**或者**after**指定该Filter放置的位置。

Spring Security对`FilterChain`中Filter顺序是有严格的规定的。Spring Security对那些内置的Filter都指定了一个别名，同时指定了它们的位置。我们在定义`custom-filter`的**position**、**before**和**after**时使用的值就是对应着这些别名所处的位置。如`position="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER对应的那个位置，`before="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER之前，`after="CAS_FILTER"`就表示将定义的Filter放在CAS_FILTER之后。此外还有两个特殊的位置可以指定，FIRST和LAST，分别对应第一个和最后一个Filter，如你想把定义好的Filter放在最后，则可以使用`after="LAST"`。

Spring Security给我们定义好的FilterChain中Filter对应的位置顺序、它们的别名以及将触发自动添加到FilterChain的元素或属性定义。下面的定义是按顺序的：

| 别名                             | Filter类                                        | 对应元素或属性                              |
| :------------------------------- | :---------------------------------------------- | ------------------------------------------- |
| **CHANNEL_FILTER**               | `ChannelProcessingFilter`                       | http>intercept-url>requires-channel         |
| **SECURITY_CONTEXT_FILTER**      | `SecurityContextPersistenceFilter`              | http                                        |
| **CONCURRENT_SESSION_FILTER**    | `ConcurrentSessionFilter`                       | http>session-management>concurrency-control |
| **LOGOUT_FILTER**                | `LogoutFilter`                                  | http>logout                                 |
| **X509_FILTER**                  | `X509AuthenticationFilter`                      | http>x509                                   |
| **PRE_AUTH_FILTER**              | `AstractPreAuthenticatedProcessingFilter`的子类 | N/A                                         |
| **CAS_FILTER**                   | `CasAuthenticationFilter`                       | N/A                                         |
| **FORM_LOGIN_FILTER**            | `UsernamePasswordAuthenticationFilter`          | http>form-login                             |
| **BASIC_AUTH_FILTER**            | `BasicAuthenticationFilter`                     | http>http-basic                             |
| **SERVLET_API_SUPPORT_FILTER**   | `SecurityContextHolderAwareRequestFilter`       | http>servlet-api-provision                  |
| **JAAS_API_SUPPORT_FILTER**      | `JaasApiIntegrationFilter`                      | http>jaas-api-provision                     |
| **REMEMBER_ME_FILTER**           | `RememberMeAuthenticationFilter`                | http>remember-me                            |
| **ANONYMOUS_FILTER**             | `AnonymousAuthenticationFilter`                 | http>anonymous                              |
| **SESSION_MANAGEMENT_FILTER**    | `SessionManagementFilter`                       | http>session-management                     |
| **EXCEPTION_TRANSLATION_FILTER** | `ExceptionTranslationFilter`                    | http                                        |
| **FILTER_SECURITY_INTERCEPTOR**  | `FilterSecurityInterceptor`                     | http                                        |
| **SWITCH_USER_FILTER**           | `SwitchUserFilter`                              | N/A                                         |

## 1.3、DelegatingFilterProxy

> 为什么明明只是定义了一个Filter，上文中为什么说是一系列呢？

```XML
<filter>
    <filter-name>springSecurityFilterChain</filter-name>
    <filter-class>org.springframework.web.filter.DelegatingFilterProxy</filter-class>
    <init-param>
       <param-name>targetBeanName</param-name>
       <param-value>springSecurityFilterChain</param-value>
    </init-param>
</filter>
<filter-mapping>
    <filter-name>springSecurityFilterChain</filter-name>
    <url-pattern>/*</url-pattern>
</filter-mapping>
```

上述的虽然只配置了一个Filter但是其内部很巧妙的利用了代理对象`DelegatingFilterProxy`将这[一系列的Filter](#1.1、Filter顺序)放入到Servlet容器中。

`DelegatingFilterProxy`是Spring中定义的一个Filter实现类，其作用是代理真正的Filter实现类。也就是说在调用`DelegatingFilterProxy`的`doFilter()`方法时实际上调用的是其代理对象的doFilter()方法。

`DelegatingFilterProxy`的代理对象，必须是一个被Spring容器管理的组件。正因为如此，其代理对象可以使用IOC方式将Spring上下文中的Bean注入到代理对象中。

那么`DelegatingFilterProxy`如何知道其所代理的Filter是哪个呢？这是通过其自身的一个叫targetBeanName的属性来确定的，通过该名称，`DelegatingFilterProxy`可以从`WebApplicationContext`中获取指定的bean作为代理对象。该属性可以通过在web.xml中定义DelegatingFilterProxy时通过init-param来指定，如果未指定的话将默认取其在web.xml中声明时定义的名称，也就是`filter-name`配置的名称。

在上述的配置当中，`DelegatingFilterProxy`代理的就是名为`springSecurityFilterChain`的Filter。

需要注意的是被代理的Filter的初始化方法init()和销毁方法destroy()默认是不会被执行的。通过设置`DelegatingFilterProxy`的`targetFilterLifecycle`属性为`true`，可以使被代理Filter与DelegatingFilterProxy具有同样的生命周期。

## 1.4、FilterChainProxy

Spring Security底层是通过[一系列的Filter](#1.1、Filter顺序)来工作的，每个Filter都有其各自的功能，而且各个Filter之间还有关联关系，所以它们的组合顺序也是非常重要的。

使用Spring Security时，`DelegatingFilterProxy`代理的就是一个`FilterChainFroxy`，其可以包含多个`SecurityFilterChain`对象。但是某个请求只会对应一个`SecurityFilterChain`，而一个`SecurityFilterChain`中又可以包含有多个Filter。

```java
public class FilterChainProxy extends GenericFilterBean {

    private final static String FILTER_APPLIED = FilterChainProxy.class.getName().concat(".APPLIED");

    // SecurityFilterChain集合
    private List<SecurityFilterChain> filterChains;
    
    // 其余内容省略
	
}
```

```java
public interface SecurityFilterChain {

    boolean matches(HttpServletRequest request);

    List<Filter> getFilters();
}
```

当我们基于XML配置的方式使用Spring Security时，系统会自动为我们注册一个名为springSecurityFilterChain类型为FilterChainProxy的bean。而且每一个http元素的定义都将拥有自己的`SecurityFilterChain`，而`SecurityFilterChain`中所拥有的Filter则会根据定义的服务自动增减。所以我们不需要显示的再定义这些Filter对应的bean了，除非你想实现自己的逻辑，需要自定义实现。

 Spring Security允许我们在配置文件中配置多个http元素，以针对不同形式的URL使用不同的安全控制。Spring Security将会为每一个http元素创建对应的`SecurityFilterChain`，同时按照它们的声明顺序加入到`FilterChainProxy`。所以当我们同时定义多个http元素时要确保将更具有特性的URL配置在前。

```xml
<security:http pattern="/login*.jsp*" security="none"/>
<security:http pattern="/admin/**">
    <security:intercept-url pattern="/**" access="ROLE_ADMIN"/>
</security:http>
<security:http>
    <security:intercept-url pattern="/**" access="ROLE_USER"/>
</security:http>
```

> http元素的pattern属性用于指定当前的http对应的FilterChain将匹配哪些URL，如未指定将匹配所有的请求

## 1.5、Spring Security内置核心的Filter

通过前面的介绍我们知道Spring Security是通过Filter来工作的，为保证Spring Security的顺利运行，其内部实现了一系列的Filter。这其中有几个是在使用Spring Security的Web应用中**必定**会用到的。接下来简要的介绍以下几个Filter：

- `FilterSecurityInterceptor`
- `ExceptionTranslationFilter`
- `SecurityContextPersistenceFilter`
- `UsernamePasswordAuthenticationFilter`

在我们使用http元素时前三者会自动添加到对应的`SecurityFilterChain`中，当我们使用了form-login元素时`UsernamePasswordAuthenticationFilter`也会自动添加到`SecurityFilterChain`中。

所以我们在利用custom-filter往`SecurityFilterChain`中添加自己定义的这些Filter时需要注意它们的位置。

### 1.5.1、FilterSecurityInterceptor

 `FilterSecurityInterceptor`是用于保护Http资源的，它需要一个`AccessDecisionManager`和一个`AuthenticationManager`的引用。它会从`SecurityContextHolder`获取`Authentication`，然后通过`FilterInvocationSecurityMetadataSource`可以得知当前请求是否在请求受保护的资源。对于请求那些受保护的资源，如果`Authentication.isAuthenticated()`返回`false`或者FilterSecurityInterceptor的alwaysReauthenticate属性为true，那么将会使用其引用的`AuthenticationManager`再认证一次，认证之后再使用认证后的Authentication替换SecurityContextHolder中拥有的那个，接着就是利用AccessDecisionManager进行权限的检查。

 我们在使用基于XML的配置时所配置的intercept-url就会跟FilterChain内部的FilterSecurityInterceptor绑定。如果要自己定义FilterSecurityInterceptor对应的bean，那么该bean定义大致如下所示：

```xml
<bean id="filterSecurityInterceptor"  
      class="org.springframework.security.web.access.intercept.FilterSecurityInterceptor">
    <property name="authenticationManager" ref="authenticationManager" />
    <property name="accessDecisionManager" ref="accessDecisionManager" />
    <property name="securityMetadataSource">
        <security:filter-security-metadata-source>
            <security:intercept-url pattern="/admin/**" access="ROLE_ADMIN" />
            <security:intercept-url pattern="/**" 		access="ROLE_USER,ROLE_ADMIN" />
        </security:filter-security-metadata-source>
    </property>
</bean>
```

`filter-security-metadata-source`用于配置其securityMetadataSource属性。

`intercept-url`用于配置需要拦截的URL与对应的角色关系。

### 1.5.2、ExceptionTranslationFilter

在Spring Security的[Filter链表](#1.1、Filter顺序)中`ExceptionTranslationFilter`放在`FilterSecurityInterceptor`的前面。而`ExceptionTranslationFilter`是捕获来自FilterChain的异常，并对这些异常做处理。

`ExceptionTranslationFilter`能够捕获来自FilterChain所有的异常，但是它只会处理两类异常，`AuthenticationException`和`AccessDeniedException`，其它的异常它会继续抛出。

- 如果捕获到的是`AuthenticationException`，那么将会使用其对应的`AuthenticationEntryPoint`的`commence()`方法进行处理。

- 如果捕获的异常是一个`AccessDeniedException`，那么将视当前访问的用户是否已经登录认证做不同的处理，如果未登录，则会使用关联的`AuthenticationEntryPoint`的`commence()`方法进行处理，否则将使用关联的`AccessDeniedHandler`的`handle()`方法进行处理。

`AuthenticationEntryPoint`是在用户**没有认证**时用于引导用户进行登录认证的，在实际应用中应根据具体的认证机制选择对应的AuthenticationEntryPoint。

`AccessDeniedHandler`用于在用户已经登录了，但是访问了其自身没有权限的资源时做出对应的处理。

`ExceptionTranslationFilter`拥有的`AccessDeniedHandler`默认是`AccessDeniedHandlerImpl`，其会返回一个403错误码到客户端。

我们可以通过显示的配置AccessDeniedHandlerImpl，同时给其指定一个errorPage使其可以返回对应的错误页面。当然我们也可以实现自己的AccessDeniedHandler，配置信息如下：

```xml
```





### 1.5.3、SecurityContextPersistenceFilter

### 1.5.4、UsernamePasswordAuthenticationFilter

