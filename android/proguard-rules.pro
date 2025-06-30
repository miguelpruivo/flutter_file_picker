#TIKA PROGUARD RULES
-keep class org.apache.tika.** { *; }
-keep class javax.xml.stream.XMLResolver.** { *; }
-dontwarn javax.xml.stream.XMLInputFactory
-dontwarn javax.xml.stream.XMLResolver
-dontwarn org.osgi.**
-dontwarn aQute.bnd.annotation.**