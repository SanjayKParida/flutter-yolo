# Keep classes used by SnakeYAML or any introspection-based library
-keep class java.beans.** { *; }
-dontwarn java.beans.**
-dontwarn java.beans.BeanInfo
-dontwarn java.beans.FeatureDescriptor
-dontwarn java.beans.IntrospectionException
-dontwarn java.beans.Introspector
-dontwarn java.beans.PropertyDescriptor