#   Created by VadNiks on Aug 28 2022
#   Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
#
#   This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
#   No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
#   without author's written permission, are strongly prohibited.
#
#   Source codes are opened only for review.

-dontobfuscate
-verbose
-printmapping mapping.txt
-android
-assumenosideeffects public @interface kotlin.Metadata {
    public <fields>;
    <fields>;
    public <methods>;
    <methods>;
}
-assumenosideeffects public @interface kotlin.coroutines.jvm.internal.DebugMetadata {
    public <fields>;
    <fields>;
    public <methods>;
    <methods>;
}