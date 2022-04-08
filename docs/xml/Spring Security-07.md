[TOC]
# 1、CachingUserDetailsService

Spring 提供了一个用于缓存`UserDetails`的`UserDetailsService`实现类：`CachingUserDetailsService`。该类的构造接收一个用于真正加载`UserDetails`的`UserDetailsService`实现类。当需要加载`UserDetails`时，其首先会从缓存中获取，如果缓存中没有对应的`UserDetails`存在，则使用持有的`UserDetailsService`实现类进行加载，然后将加载后的结果存放在缓存中。`UserDetails`与缓存的交互是通过`UserCache`接口来实现的。`CachingUserDetailsService`默认拥有`UserCache`的一个空实现引用：`NullUserCache`。以下是`CachingUserDetailsService`的类定义：

```java
public class CachingUserDetailsService implements UserDetailsService {
    private UserCache userCache = new NullUserCache();
    private final UserDetailsService delegate;

    CachingUserDetailsService(UserDetailsService delegate) {
        this.delegate = delegate;
    }

    public UserCache getUserCache() {
        return userCache;
    }

    public void setUserCache(UserCache userCache) {
        this.userCache = userCache;
    }

    public UserDetails loadUserByUsername(String username) {
        //缓存中获取UserDetails对象
        UserDetails user = userCache.getUserFromCache(username);
		//获取不到，尝试使用真正的UserDetailsService实现类获取
        if (user == null) {
            user = delegate.loadUserByUsername(username);
        }
        Assert.notNull(user, "UserDetailsService " + delegate + " returned null for username " + username + ". " +
                "This is an interface contract violation");
		//最终放入到缓存当中
        userCache.putUserInCache(user);
        return user;
    }
}
```

当缓存中不存在对应的`UserDetails`时将使用引用的`UserDetailsService`类型的delegate进行加载。加载后再把它存放到Cache中并进行返回

## 1.1、UserCache

除了`NullUserCache`之外，Spring Security还提供了基于`EhCahe`的实现类`EhCacheBasedUserCache`。源码如下：

```java
public class EhCacheBasedUserCache implements UserCache, InitializingBean {
    private static final Log logger = LogFactory.getLog(EhCacheBasedUserCache.class);
	private Ehcache cache;
    
	public void afterPropertiesSet() throws Exception {
        Assert.notNull(cache, "cache mandatory");
    }
    public Ehcache getCache() {
        return cache;
    }
    // 从EhCahe中获取UserDetails
    public UserDetails getUserFromCache(String username) {
        Element element = cache.get(username);
        if (element == null) {
            return null;
        } else {
            return (UserDetails) element.getValue();
        }
    }
    // 更新EhCahe中的UserDetails
    public void putUserInCache(UserDetails user) {
        Element element = new Element(user.getUsername(), user);
        cache.put(element);
    }
	// 从EhCahe剔除
    public void removeUserFromCache(UserDetails user) {
        this.removeUserFromCache(user.getUsername());
    }
	// 根据用户名从EhCahe剔除
    public void removeUserFromCache(String username) {
        cache.remove(username);
    }
    // 需要外部传入一个Ehcache
    public void setCache(Ehcache cache) {
        this.cache = cache;
    }
}
```

配置一个支持缓存UserDetails的CachingUserDetailsService的示例：

```xml
<security:authentication-manager alias="authenticationManager">
    <security:authentication-provider user-service-ref="cachingUserDetailsService"/>
</security:authentication-manager>

<bean id="delegate" class="com.github.CustomUserDetailsService"/>

<!-- 将使用默认的CacheManager创建一个名为ehcache4UserDetails的Ehcache对象 -->
<bean id="ehcache4UserDetails" class="org.springframework.cache.ehcache.EhCacheFactoryBean"/>

<bean id="ehCacheBasedUserCache" class="org.springframework.security.core.userdetails.cache.EhCacheBasedUserCache">
    <property name="cache" ref="ehcache4UserDetails"/>
</bean>

<bean id="cachingUserDetailsService" class="org.springframework.security.config.authentication.CachingUserDetailsService">
    <!--真正的UserDetailsService-->
    <constructor-arg name="delegate" ref="delegate"/>
    <property name= "userCache" ref="ehCacheBasedUserCache"/>
</bean>
```

通过`EhcacheFactoryBean`定义的Ehcache bean对象采用的是默认配置，其将使用默认的`CacheManager`，即直接通过`CacheManager.getInstance()`获取当前已经存在的`CacheManager`对象，如不存在则使用默认配置自动创建一个，当然这可以通过cacheManager属性指定我们需要使用的`CacheManager`，`CacheManager`可以通过`EhCacheManagerFactoryBean`进行定义。此外，如果没有指定对应缓存的名称，默认将使用beanName，在上述配置中即为*ehcache4UserDetails*，可以通过cacheName属性进行指定。此外，缓存的配置信息也都是使用的默认的。

