# okhttp (pulled in transitively by the TPL Maps SDK / http package) probes
# for optional TLS providers that aren't on the classpath in this app. R8
# fails the build over the missing references unless told to ignore them.
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
