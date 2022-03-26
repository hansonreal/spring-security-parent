[TOC]
# 1、认证

## 1.1、认证过程

1. 用户使用用户名和密码进行登录
2. Spring Security将获取到的用户名和密码封装成一个实现了`Authentication`接口的`UsernamePasswordAuthenticationToken`
3. 将上述产生的token对象传递给`AuthenticationManager`进行登录认证
4. `AuthenticationManager`认证成功后将会返回一个封装了用户权限等信息的`Authentication`对象
5. 通过调用`SecurityContextHolder.getContext().setAuthentication(..)`将`AuthenticationManager`返回的Authentication对象赋予给当前的`SecurityContext`

> 上述就是Spring Security的认证过程。在认证成功后，用户就可以继续操作去访问其它受保护的资源了，但是在访问的时候将会使用保存在`SecurityContext`中的`Authentication`对象进行相关的权限鉴定。

## 1.2、WEB应用认证过程

如果用户直接访问登录页面，那么认证过程跟上节描述的基本一致，只是在认证完成后将跳转到指定的成功页面，默认是应用的根路径。如果用户直接访问一个受保护的资源，那么认证过程将如下：

1. 引导用户进行登录，通常是重定向到一个基于form表单进行登录的页面，具体视配置而定
2. 用户输入用户名和密码后请求认证，后台还是会像上节描述的那样获取用户名和密码封装成一个`UsernamePasswordAuthenticationToken`对象，然后把它传递给`AuthenticationManager`进行认证
3. 如果认证失败将继续执行步骤1，如果认证成功则会保存返回的`Authentication`到`SecurityContext`，然后默认会将用户重定向到之前访问的页面
4. 用户登录认证成功后再次访问之前受保护的资源时就会对用户进行权限鉴定，如不存在对应的访问权限，则会返回403错误码

在上述步骤中将有很多不同的类参与，但其中主要的参与者是`ExceptionTranslationFilter`

### 1.2.1、ExceptionTranslationFilter

`ExceptionTranslationFilter`是用来处理来自`AbstractSecurityInterceptor`抛出的`AuthenticationException`和`AccessDeniedException`的。`AbstractSecurityInterceptor`是Spring Security用于拦截请求进行权限鉴定的，其拥有两个具体的子类，拦截方法调用的`MethodSecurityInterceptor`和拦截URL请求的`FilterSecurityInterceptor`。

当`ExceptionTranslationFilter`捕获到的是`AuthenticationException`时将调用`AuthenticationEntryPoint`引导用户进行登录；

当`ExceptionTranslationFilter`捕获到的是`AccessDeniedException`，并判断当前用户是否为匿名用户，如果是匿名用户，则使用`AuthenticationEntryPoint`引导用户进行登录认证，否则将返回一个表示不存在对应权限的403错误码。

## 1.2.2、SecurityContextPersistentFilter

`SecurityContext`是存放在线程池中的，而每次权限鉴定的时候都是从线程池中获取`SecurityContext`中对应的`Authentication`所拥有的权限，并且不同的request是不同的线程，那么为什么每次都可以从线程池中获取到当前用户对应的`SecurityContext`呢？

在Web应用中这是通过`SecurityContextPersistentFilter`实现的，默认情况下其会在每次请求开始的时候从session中获取`SecurityContext`，然后把它设置给`SecurityContextHolder`，在请求结束后又会将`SecurityContextHolder`所持有的`SecurityContext`保存在session中，并且清除SecurityContextHolder所持有的`SecurityContext`。

```java
public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
    throws IOException, ServletException {
    HttpServletRequest request = (HttpServletRequest) req;
    HttpServletResponse response = (HttpServletResponse) res;
    // FILTER_APPLIED --> “__spring_security_scpf_applied”
    if (request.getAttribute(FILTER_APPLIED) != null) {
        chain.doFilter(request, response);
        return;
    }
    request.setAttribute(FILTER_APPLIED, Boolean.TRUE);
    if (forceEagerSessionCreation) {
        HttpSession session = request.getSession();
    }
    HttpRequestResponseHolder holder = 
        new HttpRequestResponseHolder(request, response);
    SecurityContext contextBeforeChainExecution = 
        repo.loadContext(holder);
    try {
        // 认证前
        SecurityContextHolder.setContext(contextBeforeChainExecution);
        chain.doFilter(holder.getRequest(), holder.getResponse());
    } finally {
        // 认证后
        SecurityContext contextAfterChainExecution = 
            SecurityContextHolder.getContext();
        SecurityContextHolder.clearContext();
        repo.saveContext(contextAfterChainExecution, 
                         holder.getRequest(), holder.getResponse());
        request.removeAttribute(FILTER_APPLIED);
    }
}
```

这样当我们第一次访问系统的时候，`SecurityContextHolder`所持有的`SecurityContext`肯定是空的，待我们登录成功后，`SecurityContextHolder`所持有的`SecurityContext`就不是空的了，且包含有认证成功的`Authentication`对象，待请求结束后我们就会将`SecurityContext`存在session中，等到下次请求的时候就可以从session中获取到该`SecurityContext`并把它赋予给`SecurityContextHolder`了，由于`SecurityContextHolder`已经持有认证过的Authentication对象了，所以下次访问的时候也就不再需要进行登录认证了。

