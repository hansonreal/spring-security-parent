[TOC]
# 1、异常信息国际化

 Spring Security支持将展现给终端用户看的异常信息本地化，这些信息包括认证失败、访问被拒绝等。而对于展现给开发者看的异常信息和日志信息（如配置错误）则是不能够进行本地化的，它们是以英文硬编码在Spring Security的代码中的。在Spring-Security-core-xxx.jar包的org.springframework.security包下拥有一个以英文异常信息为基础的messages.properties文件，以及其它一些常用语言的异常信息对应的文件，如messages_zh_CN.properties文件。那么对于用户而言所需要做的就是在自己的ApplicationContext中定义如下这样一个bean。

```xml
<bean id="messageSource"
		class="org.springframework.context.support.ReloadableResourceBundleMessageSource">
 	<property name="basename" value="classpath:org/springframework/security/messages" />
</bean>
```

 如果要自己定制messages.properties文件，或者需要新增本地化支持文件，则可以copy Spring Security提供的默认messages.properties文件，将其中的内容进行修改后再注入到上述bean中。比如我要定制一些中文的提示信息，那么我可以在copy一个messages.properties文件到类路径的“com/xxx”下，然后将其重命名为messages_zh_CN.properties，并修改其中的提示信息。然后通过basenames属性注入到上述bean中，如：

```xml
<bean id="messageSource"
   class="org.springframework.context.support.ReloadableResourceBundleMessageSource">
      <property name="basenames">
         <array>
            <value>classpath:com/xxx/messages</value>
            <value>classpath:org/springframework/security/messages</value>
         </array>
      </property>
</bean>
```

> 需要注意的是将自定义的messages.properties文件路径定义在Spring Security内置的message.properties路径定义之前。
