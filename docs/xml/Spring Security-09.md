[TOC]

# 1、Spring Security Filter

> Spring Security的底层是通过一系列的Filter来管理的，每个Filter都有其自身的功能，而且各个Filter在功能上还有关联关系，所以它们的顺序也是非常重要的。

## 1.1、Filter顺序

 Spring Security已经定义了一些Filter，不管实际应用中你用到了哪些，它们应当保持如下顺序：

- ChannelProcessingFilter：如果你访问的channel错了，那首先就会在channel之间进行跳转，如http变为https。
- SecurityContextPersistenceFilter：该过滤器只会在每次请求之前执行一次，一旦请求进来的时候就可以在SecurityContextHolder中建立一个SecurityContext，然后在请求结束的时候，任何对SecurityContext的改变都可以被copy到HttpSession。
- ConcurrentSessionFilter：因为它需要使用SecurityContextHolder的功能，而且更新对应session的最后更新时间，以及通过SessionRegistry获取当前的SessionInformation以检查当前的session是否已经过期，过期则会调用LogoutHandler。
- 认证处理机制，如UsernamePasswordAuthenticationFilter，CasAuthenticationFilter，BasicAuthenticationFilter等，以便于SecurityContextHolder可以被更新为包含一个有效的Authentication请求。
- SecurityContextHolderAwareRequestFilter：将会把HttpServletRequest封装成一个继承自HttpServletRequestWrapper的SecurityContextHolderAwareRequestWrapper，同时使用SecurityContext实现了HttpServletRequest中与安全相关的方法。



## 1.2、添加Filter到FilterChain

## 1.3、DelegatingFilterProxy

## 1.4、FilterChainProxy

## 1.5、Spring Security内置核心的Filter

### 1.5.1、FilterSecurityInterceptor

### 1.5.2、ExceptionTranslationFilter

### 1.5.3、SecurityContextPersistenceFilter

### 1.5.4、UsernamePasswordAuthenticationFilter

