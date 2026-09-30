BMT GO v30 — Android / Google Play preparation

- Version 1.8.0+30.
- Android applicationId: com.bmtgo.app.
- Android launcher icon: BMT GO black/yellow brand.
- Android permissions prepared for Internet, location and notifications.
- Android Gradle/Kotlin project scaffold added for an AAB build.
- Existing v25-v29 features are preserved.

Before production release:
1. Add real Supabase/Firebase production credentials.
2. Add Google Maps API key and Firebase google-services configuration if used.
3. Configure a release signing keystore; never commit the keystore/password.
4. Add privacy policy URL and Google Play Data Safety declarations.
5. Test login, maps, GPS, push, payments and payouts on physical Android devices.
6. Build signed AAB with Flutter: flutter build appbundle --release.
