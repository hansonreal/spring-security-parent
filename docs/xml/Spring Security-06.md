[TOC]
# 1、AuthenticationProvider

认证是由`AuthenticationManager`来管理的，但是它本身并不去处理而是交给了`ProviderManager`其内部维护了一个`AuthenticationProvider`集合。

```java
public class ProviderManager implements AuthenticationManager,XX{
    private List<AuthenticationProvider> providers = Collections.emptyList();
    // 省略代码xxx
}
```

当我们使用`authentication-provider`来定义一个`AuthenticationProvider`时，如果没有指定对应关联的`AuthenticationProvider`对象，Spring Security默认会使用`DaoAuthenticationProvider`。

```xml
<security:authentication-manager>
    <security:authentication-provider ref="customizeAuthenticationProvider">
    </security:authentication-provider>
</security:authentication-manager>
```

`DaoAuthenticationProvider`在进行认证的时候需要一个`UserDetailsService`来获取用户的信息`UserDetails`，其中包括用户名、密码和所拥有的权限等。所以如果我们需要改变认证的方式，我们可以实现自己的`AuthenticationProvider`；如果需要改变认证的用户信息来源，我们可以实现`UserDetailsService`。

```xml
<security:authentication-manager>
 <security:authentication-provider user-service-ref="customizeUserDetailsService"/>
</security:authentication-manager>
```

## 1.1、从数据库中获取用户信息

通常情况下用户的信息是不会直接配置在XML文件中，而是存在数据库中。而想从其他地方获取用户信息，我们就需要实现`UserDetailsService`类，从而从数据库中获取用户信息。而Spring Security也已经提供了一个实现类`JdbcDaoImpl` 。

### 1.1.1、使用jdbc-user-service获取

在Spring Security的命名空间中在`authentication-provider`下定义了一个`jdbc-user-service`元素，通过该元素我们可以定义一个从数据库获取`UserDetails`的`UserDetailsService`。`jdbc-user-service`需要接收一个数据源的引用。

```xml
<bean id="dataSource" class="xxx.xxx.xxDataSource"/>
<security:authentication-manager>
    <security:authentication-provider>
        <security:jdbc-user-service data-source-ref="dataSource"/>
    </security:authentication-provider>
</security:authentication-manager>
```

上述配置中dataSource是对应数据源配置的bean引用。使用此种方式需要我们的数据库拥有如下表和表结构：

参考[第三章节部分](./Spring Security-03.md#151jdbcdaoimplddml)

当然这只是默认配置及默认的表结构。如果我们的表名或者表结构跟Spring Security默认的不一样，我们可以通过以下几个属性来定义我们自己查询用户信息、用户权限和用户组权限的SQL。

| 属性名                              | 说明                    |
| :---------------------------------- | :---------------------- |
| users-by-username-query             | 指定查询用户信息的SQL   |
| authorities-by-username-query       | 指定查询用户权限的SQL   |
| group-authorities-by-username-query | 指定查询用户组权限的SQL |

假设我们的用户表是t_user，而不是默认的users，则我们可以通过属性`users-by-username-query`来指定查询用户信息的时候是从用户表t_user查询

```xml
<security:authentication-manager>
  <security:authentication-provider>
     <security:jdbc-user-service
       data-source-ref="dataSource"
       users-by-username-query="select username, password, enabled 
                                from t_user 
                                where username = ?"/>
    </security:authentication-provider>
</security:authentication-manager>
```

` jdbc-user-service`还有一个属性`role-prefix`可以用来指定角色的前缀。这是什么意思呢？这表示我们从库里面查询出来的权限需要加上什么样的前缀。举个例子，假设我们库里面存放的权限都是`“USER”`，而我们指定了某个URL的访问权限`access=”ROLE_USER”`，显然这是不匹配的，Spring Security不会给我们放行，通过指定`jdbc-user-service的role-prefix=”ROLE_”`之后就会满足了。当`role-prefix`的值为`none`时表示没有前缀，当然默认也是没有的。

### 1.1.2、通过JdbcDaoImpl获取

 `JdbcDaoImpl`是`UserDetailsService`的一个实现。其用法和`jdbc-user-service`类似，只是我们需要把它定义为一个bean，然后通过`authentication-provider`的`user-service-ref`进行引用。

```xml
<bean id="userDetailsService" class="org.springframework.security.core.userdetails.jdbc.JdbcDaoImpl">
    <property name="dataSource" ref="dataSource"/>
</bean>
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService"/>
</security:authentication-manager>
```

`JdbcDaoImpl`同样需要一个dataSource的引用。如果就是上面这样配置的话我们数据库表结构也需要是标准的表结构。当然，如果我们的表结构和标准的不一样，可以通过`usersByUsernameQuery`、`authoritiesByUsernameQuery`和`groupAuthoritiesByUsernameQuery`属性来指定对应的查询SQL。

```xml
<bean id="userDetailsService" class="org.springframework.security.core.userdetails.jdbc.JdbcDaoImpl">
    <property name="dataSource" ref="dataSource"/>
    <property name="enableGroups" value="true"/>
    <property name="enableAuthorities" value="true"/>
</bean>
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService"/>
</security:authentication-manager>
```

`JdbcDaoImpl`使用`enableAuthorities`和`enableGroups`两个属性来控制权限的启用。默认启用的是`enableAuthorities`，即用户权限，而`enableGroups`默认是不启用的。如果需要启用用户组权限，需要指定`enableGroups`属性值为`true`。当然这两种权限是可以同时启用的。需要注意的是使用`jdbc-user-service`定义的`UserDetailsService`是不支持用户组权限的，如果需要支持用户组权限的话需要我们使用`JdbcDaoImpl`。

## 1.2、PasswordEncoder

