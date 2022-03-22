[TOC]

# 1、核心类介绍

## 1.1、Authentication

Authentication是一个接口，用来表示用户认证信息的，在用户登录认证之前相关信息会封装为一个Authentication具体实现类的对象，在登录认证成功之后又会生成一个信息更全面，包含用户权限等信息的Authentication对象，然后把它保存在SecurityContextHolder所持有的SecurityContext中，供后续的程序进行调用，如访问权限的鉴定等。

## 1.2、SecurityContextHolder

SecurityContextHolder是用来保存SecurityContext的。SecurityContext中含有当前正在访问系统的用户的详细信息。默认情况下，SecurityContextHolder将使用ThreadLocal来保存SecurityContext，这也就意味着在处于同一线程中的方法中我们可以从ThreadLocal中获取到当前的SecurityContext。因为线程池的原因，如果我们每次在请求完成后都将ThreadLocal进行清除的话，那么我们把SecurityContext存放在ThreadLocal中还是比较安全的。这些工作Spring Security已经自动为我们做了，即在每一次request结束后都将清除当前线程的ThreadLocal。

SecurityContextHolder中定义了一系列的静态方法，而这些静态方法内部逻辑基本上都是通过SecurityContextHolder持有的SecurityContextHolderStrategy来实现的，如getContext()、setContext()、clearContext()等。而默认使用的strategy就是基于ThreadLocal的ThreadLocalSecurityContextHolderStrategy。另外，Spring Security还提供了两种类型的strategy实现，GlobalSecurityContextHolderStrategy和InheritableThreadLocalSecurityContextHolderStrategy，前者表示全局使用同一个SecurityContext，如C/S结构的客户端；后者使用InheritableThreadLocal来存放SecurityContext，即子线程可以使用父线程中存放的变量。

一般而言，我们使用默认的strategy就可以了，但是如果要改变默认的strategy，Spring Security为我们提供了两种方法，这两种方式都是通过改变strategyName来实现的。SecurityContextHolder中为三种不同类型的strategy分别命名为MODE_THREADLOCAL、MODE_INHERITABLETHREADLOCAL和MODE_GLOBAL。第一种方式是通过SecurityContextHolder的静态方法setStrategyName()来指定需要使用的strategy；第二种方式是通过系统属性进行指定，其中属性名默认为“spring.security.strategy”，属性值为对应strategy的名称。

```java
private static void initialize() {
        if ((strategyName == null) || "".equals(strategyName)) {
            strategyName = MODE_THREADLOCAL;
        }
        if (strategyName.equals(MODE_THREADLOCAL)) {
            strategy = new ThreadLocalSecurityContextHolderStrategy();
        } else if (strategyName.equals(MODE_INHERITABLETHREADLOCAL)) {
            strategy = new InheritableThreadLocalSecurityContextHolderStrategy();
        } else if (strategyName.equals(MODE_GLOBAL)) {
            strategy = new GlobalSecurityContextHolderStrategy();
        } else {
            try {
                Class<?> clazz = Class.forName(strategyName);
                Constructor<?> customStrategy = clazz.getConstructor();
                strategy = (SecurityContextHolderStrategy) customStrategy.newInstance();
            } catch (Exception ex) {
                ReflectionUtils.handleReflectionException(ex);
            }
        }
        initializeCount++;
}
```

Spring Security使用一个Authentication对象来描述当前用户的相关信息。SecurityContextHolder中持有的是当前用户的SecurityContext，而SecurityContext持有的是代表当前用户相关信息的Authentication的引用。这个Authentication对象不需要我们自己去创建，在与系统交互的过程中，Spring Security会自动为我们创建相应的Authentication对象，然后赋值给当前的SecurityContext。但是往往我们需要在程序中获取当前用户的相关信息，比如最常见的是获取当前登录用户的用户名。在程序的任何地方，通过如下方式我们可以获取到当前用户的用户名。

```java
public String getName() {
    if (this.getPrincipal() instanceof UserDetails) {
        return ((UserDetails) this.getPrincipal()).getUsername();
    }
    if (getPrincipal() instanceof Principal) {
        return ((Principal)getPrincipal()).getName();
    }
    return (this.getPrincipal() == null) ? "" : this.getPrincipal().toString();
}
```

通过Authentication.getPrincipal()可以获取到代表当前用户的信息，这个对象通常是UserDetails的实例。获取当前用户的用户名是一种比较常见的需求，关于上述代码其实Spring Security在Authentication中的实现类中已经为我们做了相关实现，所以获取当前用户的用户名最简单的方式应当如下:

```java
public String getCurrentUsername() {
	return SecurityContextHolder.getContext().getAuthentication().getName();
}
```

此外，调用SecurityContextHolder.getContext()获取SecurityContext时，如果对应的SecurityContext不存在，则Spring Security将为我们建立一个空的SecurityContext并进行返回。

## 1.3、AuthenticationManager

AuthenticationManager是一个用来处理认证（Authentication）请求的接口。在其中只定义了一个方法authenticate()，该方法只接收一个代表认证请求的Authentication对象作为参数，如果认证成功，则会返回一个封装了当前用户权限等信息的Authentication对象进行返回。

```java
public interface AuthenticationManager {
    Authentication authenticate(Authentication authentication) 
        throws AuthenticationException;
}
```

## 1.4、AuthenticationProvider

在Spring Security中AuthenticationManager的默认实现是ProviderManager，其内部维护了一个AuthenticationProvider列表。通过循环该列表进行依次认证，如果有一个AuthenticationProvider认证后的结果不为null，则表示该AuthenticationProvider已经认证成功，之后的AuthenticationProvider将不再继续认证。然后直接以该AuthenticationProvider的认证结果作为ProviderManager的认证结果。如果所有的AuthenticationProvider的认证结果都为null，则表示认证失败，将抛出一个ProviderNotFoundException。

```java
for (AuthenticationProvider provider : getProviders()) {
     // xxx 省略
    try {
        result = provider.authenticate(authentication);
        if (result != null) {
            copyDetails(authentication, result);
            break;
        }
    } catch (AccountStatusException e) {
        // xxx 省略
    }
}
```

校验认证请求最常用的方法是根据请求的用户名加载对应的UserDetails，然后比对UserDetails的密码与认证请求的密码是否一致，一致则表示认证通过。Spring Security内部的DaoAuthenticationProvider该类继承了AbstractUserDetailsAuthenticationProvider就是使用的这种方式。其内部使用`UserDetailsService`来负责加载UserDetails，在认证成功以后会使用加载的UserDetails来封装要返回的Authentication对象，加载的UserDetails对象是包含用户权限等信息的。认证成功返回的Authentication对象将会保存在当前的SecurityContext中。

```java
public Authentication authenticate(Authentication authentication) 
    	throws AuthenticationException {
    String username = (authentication.getPrincipal() == null) 
        	? "NONE_PROVIDED" : authentication.getName();
    boolean cacheWasUsed = true;
    UserDetails user = this.userCache.getUserFromCache(username);
    if (user == null) {
        cacheWasUsed = false;
        try {
            user = retrieveUser(username, 
                                (UsernamePasswordAuthenticationToken) authentication);
        } catch (UsernameNotFoundException notFound) {
            //xxxx 省略
        }
    }
    // xxx 省略
}
// retrieveUser交给子类实现，例如DaoAuthenticationProvider
protected abstract UserDetails retrieveUser(String username, 
                          		UsernamePasswordAuthenticationToken authentication)
        throws AuthenticationException;
```

 ```java
 protected final UserDetails retrieveUser(String username, 
                                    UsernamePasswordAuthenticationToken authentication)
             throws AuthenticationException {
         UserDetails loadedUser;
         try {
             // 交给子类实现，内部自带实现常用的有JdbcDaoImpl、InMemoryDaoImpl
             loadedUser = this.getUserDetailsService().loadUserByUsername(username);
         } catch (UsernameNotFoundException notFound) {
             //异常处理
         }
         return loadedUser;
     }
 ```

默认情况下，在认证成功后ProviderManager将清除返回的Authentication中的凭证信息，如密码。所以如果你在无状态的应用中将返回的Authentication信息缓存起来了，那么以后你再利用缓存的信息去认证将会失败，因为它已经不存在密码这样的凭证信息了。所以在使用缓存的时候你应该考虑到这个问题。一种解决办法是设置ProviderManager的eraseCredentialsAfterAuthentication 属性为false，或者想办法在缓存时将凭证信息一起缓存。

```java
if (result != null) {
    if (eraseCredentialsAfterAuthentication && (result instanceof CredentialsContainer)) {
        // Authentication is complete. Remove credentials and other 
        // secret data from authentication
        ((CredentialsContainer)result).eraseCredentials();
    }
    eventPublisher.publishAuthenticationSuccess(result);
    return result;
}
```

当使用XML配置方式时，authentication-manager元素的使用会使Spring Security 在内部创建一个ProviderManager，然后可以通过authentication-provider元素往其中添加AuthenticationProvider。当定义authentication-provider元素时，如果没有通过ref属性指定关联哪个AuthenticationProvider，Spring Security默认就会使用DaoAuthenticationProvider。使用了XML配置后我们就不要再声明ProviderManager了。

```xml
<bean id="userDetailsService" class="com.github.security.UserDetailsServiceImpl"/>
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService"/>
</security:authentication-manager>
```

如果我们没有使用XML配置方式，那么我们就应该在ApplicationContext中声明一个ProviderManager。

## 1.5、UserDetailsService

通过Authentication.getPrincipal()的返回类型是Object，但很多情况下其返回的其实是一个UserDetails的实例。UserDetails是Spring Security中一个核心的接口。其中定义了一些可以获取用户名、密码、权限等与认证相关的信息的方法。Spring Security内部使用的UserDetails实现类大都是内置的User类，我们如果要使用UserDetails时也可以直接使用该类。在Spring Security内部很多地方需要使用用户信息的时候基本上都是使用的UserDetails，比如在登录认证的时候。登录认证的时候Spring Security会通过UserDetailsService的loadUserByUsername()方法获取对应的UserDetails进行认证，认证通过后会将该UserDetails赋给认证通过的Authentication的principal，然后再把该Authentication存入到SecurityContext中。之后如果需要使用用户信息的时候就是通过SecurityContextHolder获取存放在SecurityContext中的Authentication的principal。

通常我们需要在应用中获取当前用户的其它信息，如Email、电话等。这时存放在Authentication的principal中只包含有认证相关信息的UserDetails对象可能就不能满足我们的要求了。这时我们可以实现自己的UserDetails，在该实现类中我们可以定义一些获取用户其它信息的方法，这样将来我们就可以直接从当前SecurityContext的Authentication的principal中获取这些信息了。上文已经提到了UserDetails是通过UserDetailsService的loadUserByUsername()方法进行加载的。UserDetailsService也是一个接口，我们也需要实现自己的UserDetailsService来加载我们自定义的UserDetails信息。然后把它指定给AuthenticationProvider即可。如下是一个配置UserDetailsService的示例：

```xml
<bean id="userDetailsService"
      class="org.springframework.security.core.userdetails.jdbc.JdbcDaoImpl">
      <property name="dataSource" ref="dataSource" />
</bean>
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService"/>
</security:authentication-manager>
```

上述代码中我们使用的JdbcDaoImpl是Spring Security为我们提供的UserDetailsService的实现，另外Spring Security还为我们提供了UserDetailsService另外一个实现`InMemoryDaoImpl`。其作用是从数据库中加载UserDetails信息。其中已经定义好了加载相关信息的默认脚本，这些脚本也可以通过JdbcDaoImpl的相关属性进行指定。

### 1.5.1、JdbcDaoImpl

JdbcDaoImpl允许我们从数据库来加载UserDetails，其底层使用的是Spring的JdbcTemplate进行操作，所以我们需要给其指定一个数据源。此外，我们需要通过usersByUsernameQuery属性指定通过username查询用户信息的SQL语句；通过authoritiesByUsernameQuery属性指定通过username查询用户所拥有的权限的SQL语句；如果我们通过设置JdbcDaoImpl的enableGroups为true启用了用户组权限的支持，则我们还需要通过groupAuthoritiesByUsernameQuery属性指定根据username查询用户组权限的SQL语句。当这些信息都没有指定时，将使用默认的SQL语句，默认的SQL语句如下所示：

```java
public class JdbcDaoImpl extends JdbcDaoSupport implements UserDetailsService {
    // 通过username查询用户信息
    public static final String DEF_USERS_BY_USERNAME_QUERY =
            "select username,password,enabled " +
            "from users " +
            "where username = ?";
    // 通过username查询用户所拥有的权限
    public static final String DEF_AUTHORITIES_BY_USERNAME_QUERY =
            "select username,authority " +
            "from authorities " +
            "where username = ?";
    // 根据username查询用户组权限
    public static final String DEF_GROUP_AUTHORITIES_BY_USERNAME_QUERY =
            "select g.id, g.group_name, ga.authority " +
            "from groups g, group_members gm, group_authorities ga " +
            "where gm.username = ? " +
            "and g.id = ga.group_id " +
            "and g.id = gm.group_id";
    //xxx 省略
}
```

使用默认的SQL语句进行查询时意味着我们对应的数据库中应该有对应的表和表结构，Spring Security为我们提供的默认表的创建脚本如下：

- 用户表：

  ```sql
  create table users(
      username varchar_ignorecase(50) not null primary key,
      password varchar_ignorecase(50) not null,
      enabled boolean not null);
  ```

- 权限表：

  ```sql
  create table authorities (
   username varchar_ignorecase(50) not null,
   authority varchar_ignorecase(50) not null,
   constraint fk_authorities_users foreign key(username) references users(username)
  );
  create unique index ix_auth_username on authorities (username,authority);
  ```

- 分组表：

  ```sql
  create table groups (
  	id bigint generated by default as identity(start with 0) primary key,
    	group_name varchar_ignorecase(50) notnull
  );
  ```

- 分组权限表：

  ```sql
  create table group_authorities (
    group_id bigint notnull,
    authority varchar(50) notnull,
    constraint fk_group_authorities_group foreign key(group_id) references groups(id)
  );
  ```

- 分组成员表：

  ```sql
  create table group_members (
    id bigint generated by default as identity(start with 0) primary key,
    username varchar(50) notnull,
    group_id bigint notnull,
    constraint fk_group_members_group foreign key(group_id) references groups(id)
  );
  ```

此外，使用jdbc-user-service元素时在底层Spring Security默认使用的就是JdbcDaoImpl。

```xml
<security:authentication-manager alias="authenticationManager">
      <security:authentication-provider>
         <!-- 基于Jdbc的UserDetailsService实现，JdbcDaoImpl -->
         <security:jdbc-user-service data-source-ref="dataSource"/>
      </security:authentication-provider>
</security:authentication-manager>
```

### 1.5.2、InMemoryDaoImpl

InMemoryDaoImpl主要是测试用的，其只是简单的将用户信息保存在内存中。使用NameSpace时，使用user-service元素Spring Security底层使用的UserDetailsService就是InMemoryDaoImpl。此时，我们可以简单的使用user元素来定义一个UserDetails。

```xml
<security:user-service>
    <security:user name="user" password="user" authorities="ROLE_USER"/>
</security:user-service>
```

如上配置表示我们定义了一个用户user，其对应的密码为user，拥有ROLE_USER的权限。此外，user-service还支持通过properties文件来指定用户信息，如：

```xml
<security:user-service properties="/WEB-INF/config/users.properties"/>
```

其中属性文件应遵循如下格式：

```properties
username=password,grantedAuthority[,grantedAuthority][,enabled|disabled]
```

所以，对应上面的配置文件，我们的users.properties文件的内容应该如下所示：

```properties
# 属性文件格式
# username=password,grantedAuthority[,grantedAuthority][,enabled|disabled]
hanson=hanson,ROLE_USER
security=security,ROLE_USER,ROLE_ADMIN
```

## 1.6、GrantedAuthority

Authentication的getAuthorities()可以返回当前Authentication对象拥有的权限，即当前用户拥有的权限。其返回值是一个GrantedAuthority类型的数组，每一个GrantedAuthority对象代表赋予给当前用户的一种权限。GrantedAuthority是一个接口，其通常是通过UserDetailsService进行加载，然后赋予给UserDetails的。

GrantedAuthority中只定义了一个getAuthority()方法，该方法返回一个字符串，表示对应权限的字符串表示，如果对应权限不能用字符串表示，则应当返回null。

Spring Security针对GrantedAuthority有一个简单实现SimpleGrantedAuthority。该类只是简单的接收一个表示权限的字符串。Spring Security内部的所有AuthenticationProvider都是使用SimpleGrantedAuthority来封装Authentication对象。

