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

### 1.2.1  使用内置的PasswordEncoder

通常我们保存的密码都不会按照明文保存，而是保存加密之后的结果。为此，我们需要在`AuthenticationProvider`在做认证时也需要将传递的明文密码使用对应的算法加密后再与保存好的密码做比较。

Spring Security对这方面也有支持。通过在`authentication-provider`下定义一个`password-encoder`我们可以定义当前`AuthenticationProvider`需要在进行认证时需要使用的`password-encoder`。

password-encoder是一个PasswordEncoder的实例，我们可以直接使用它，如：

```xml
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService">
        <security:password-encoder hash="md5"/>
    </security:authentication-provider>
</security:authentication-manager>
```

 其属性hash表示我们将用来进行加密的哈希算法，系统已经为我们实现的有plaintext、sha、sha-256、md4、md5、{sha}和{ssha}。它们对应的

`org.springframework.security.authentication.encoding.PasswordEncoder`实现类如下：

| 加密算法    | PasswordEncoder实现类                                 |
| :-------- | ----------------------------------------------------- |
| plaintext | PlaintextPasswordEncoder                              |
| sha       | ShaPasswordEncoder                                    |
| sha-256   | ShaPasswordEncoder，使用时new ShaPasswordEncoder(256) |
| md4       | Md4PasswordEncoder                                    |
| md5       | Md5PasswordEncoder                                    |
| {sha}     | LdapShaPasswordEncoder                                |
| {ssha}    | LdapShaPasswordEncoder                                |

#### 1.2.1.1 使用BASE64编码加密后的密码

使用password-encoder时我们还可以指定一个属性base64，表示是否需要对加密后的密码使用BASE64进行编码，默认是false。如果需要则设为true。

```xml
<security:password-encoder hash="md5" base64="true"/>
```

#### 1.2.1.2、加密时使用salt

加密时使用salt也是很常见的需求，Spring Security内置的password-encoder也对它有支持。通过password-encoder元素下的子元素salt-source，我们可以指定当前PasswordEncoder需要使用的salt。这个salt可以是一个常量，也可以是当前UserDetails的某一个属性，还可以通过实现`SaltSource`接口实现自己的获取salt的逻辑，`SaltSource`中只定义了如下一个方法:

```java
public interface SaltSource {
    Object getSalt(UserDetails user);
}
```

#### 1.2.1.3、使用常量“abc”作为salt

```xml
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService">
        <security:password-encoder hash="md5" base64="true">
            <security:salt-source system-wide="abc"/>
        </security:password-encoder>
    </security:authentication-provider>
</security:authentication-manager>
```

#### 1.2.1.4、使用UserDetails的username作为salt

```xml
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService">
        <security:password-encoder hash="md5" base64="true">
            <security:salt-source user-property="username"/>
        </security:password-encoder>
    </security:authentication-provider>
</security:authentication-manager>
```

#### 1.2.1.5、自定义实现

```xml
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService">
        <security:password-encoder hash="md5" base64="true">
            <security:salt-source ref="mySaltSource"/>
        </security:password-encoder>
    </security:authentication-provider>
</security:authentication-manager>
<bean id="mySaltSource" class="com.github.MySaltSource"/>
```

需要注意的是`AuthenticationProvider`进行认证时所使用的`PasswordEncoder`，包括它们的算法和规则都应当与我们保存用户密码时是一致的。也就是说如果`AuthenticationProvider`使用`Md5PasswordEncoder`进行认证，我们在保存用户密码时也需要使用`Md5PasswordEncoder`；如果`AuthenticationProvider`在认证时使用了username作为salt，那么我们在保存用户密码时也需要使用username作为salt。如:

```java
Md5PasswordEncoder encoder = new Md5PasswordEncoder();

encoder.setEncodeHashAsBase64(true);

System.out.println(encoder.encodePassword("user", "user"));
```

### 1.2.2、使用自定义PasswordEncoder

除了通过password-encoder使用Spring Security已经为我们实现了的PasswordEncoder之外，我们也可以实现自己的PasswordEncoder，然后通过password-encoder的ref属性关联到我们自己实现的PasswordEncoder对应的bean对象。

```xml
<security:authentication-manager>
    <security:authentication-provider user-service-ref="userDetailsService">
        <security:password-encoder ref="passwordEncoder"/>
    </security:authentication-provider>
</security:authentication-manager>
<bean id="passwordEncoder" class="com.github.MyPasswordEncoder"/>
```

在Spring Security内部定义有两种类型的PasswordEncoder，分别是：

- `org.springframework.security.authentication.encoding.PasswordEncoder`
- `org.springframework.security.crypto.password.PasswordEncoder`

直接通过password-encoder元素的hash属性指定使用内置的PasswordEncoder都是基于org.springframework.security.authentication.encoding.PasswordEncoder的实现，然而它现在已经被废弃了，Spring Security推荐我们使用org.springframework.security.crypto.password.PasswordEncoder，它的设计理念是为了使用随机生成的salt。关于后者Spring Security也已经提供了几个实现类：

| PasswordEncoder实现类       | 加密器说明                                             |
| --------------------------- | ------------------------------------------------------ |
| **NoOpPasswordEncoder**     | 用于测试阶段                                           |
| **StandardPasswordEncoder** | 标准加密器，SHA-256+10位随机数进行1024次迭代计算出密文 |
| **BCryptPasswordEncoder**   | 单向HASH，不可逆                                       |

我们在通过password-encoder使用自定义的PasswordEncoder时两种PasswordEncoder的实现类都是支持的
