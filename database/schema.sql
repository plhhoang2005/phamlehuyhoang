CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "Subjects" (
        "Id" uuid NOT NULL,
        "Code" character varying(20) NOT NULL,
        "Name" character varying(150) NOT NULL,
        "Credits" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_Subjects" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "Users" (
        "Id" uuid NOT NULL,
        "Username" character varying(50) NOT NULL,
        "Email" character varying(100) NOT NULL,
        "FullName" character varying(100) NOT NULL,
        "StudentCode" character varying(50),
        "PasswordHash" text NOT NULL,
        "Role" character varying(20) NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "FaceEmbedding" bytea,
        "FaceRegisteredAtUtc" timestamp with time zone,
        "IsActive" boolean NOT NULL,
        CONSTRAINT "PK_Users" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "CourseClasses" (
        "Id" uuid NOT NULL,
        "Code" character varying(50) NOT NULL,
        "SubjectId" uuid NOT NULL,
        "LecturerId" uuid,
        "TotalSessions" integer NOT NULL,
        "MaxAbsencesAllowed" integer NOT NULL,
        "DefaultLatitude" double precision NOT NULL,
        "DefaultLongitude" double precision NOT NULL,
        "DefaultRadiusMeters" double precision NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_CourseClasses" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_CourseClasses_Subjects_SubjectId" FOREIGN KEY ("SubjectId") REFERENCES "Subjects" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_CourseClasses_Users_LecturerId" FOREIGN KEY ("LecturerId") REFERENCES "Users" ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "OtpChallenges" (
        "Id" uuid NOT NULL,
        "Ticket" character varying(100) NOT NULL,
        "UserId" uuid NOT NULL,
        "Code" character varying(6) NOT NULL,
        "Purpose" character varying(30) NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "ExpiresAtUtc" timestamp with time zone NOT NULL,
        "AttemptCount" integer NOT NULL,
        "IsUsed" boolean NOT NULL,
        "LastSentAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_OtpChallenges" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_OtpChallenges_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "ClassEnrollments" (
        "Id" uuid NOT NULL,
        "CourseClassId" uuid NOT NULL,
        "StudentId" uuid NOT NULL,
        "EnrolledAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_ClassEnrollments" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ClassEnrollments_CourseClasses_CourseClassId" FOREIGN KEY ("CourseClassId") REFERENCES "CourseClasses" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ClassEnrollments_Users_StudentId" FOREIGN KEY ("StudentId") REFERENCES "Users" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "ClassSessions" (
        "Id" uuid NOT NULL,
        "CourseClassId" uuid NOT NULL,
        "SessionNumber" integer NOT NULL,
        "Title" character varying(150) NOT NULL,
        "StartTimeUtc" timestamp with time zone NOT NULL,
        "EndTimeUtc" timestamp with time zone NOT NULL,
        "RoomName" character varying(50) NOT NULL,
        "Latitude" double precision NOT NULL,
        "Longitude" double precision NOT NULL,
        "RadiusMeters" double precision NOT NULL,
        "IsCancelled" boolean NOT NULL,
        "IsFinalized" boolean NOT NULL,
        "FinalizedAtUtc" timestamp with time zone,
        "FinalizedByUserId" uuid,
        CONSTRAINT "PK_ClassSessions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ClassSessions_CourseClasses_CourseClassId" FOREIGN KEY ("CourseClassId") REFERENCES "CourseClasses" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "AttendanceQrSessions" (
        "Id" uuid NOT NULL,
        "ClassSessionId" uuid NOT NULL,
        "QrToken" character varying(100) NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "ExpiresAtUtc" timestamp with time zone NOT NULL,
        "IsOpen" boolean NOT NULL,
        CONSTRAINT "PK_AttendanceQrSessions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AttendanceQrSessions_ClassSessions_ClassSessionId" FOREIGN KEY ("ClassSessionId") REFERENCES "ClassSessions" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "AttendanceRecords" (
        "Id" uuid NOT NULL,
        "ClassSessionId" uuid NOT NULL,
        "StudentId" uuid NOT NULL,
        "Status" integer NOT NULL,
        "CheckedInAtUtc" timestamp with time zone,
        "CheckInMethod" character varying(50) NOT NULL,
        "StudentLatitude" double precision,
        "StudentLongitude" double precision,
        "DistanceMeters" double precision,
        "AccuracyMeters" double precision,
        "Note" character varying(250),
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_AttendanceRecords" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AttendanceRecords_ClassSessions_ClassSessionId" FOREIGN KEY ("ClassSessionId") REFERENCES "ClassSessions" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_AttendanceRecords_Users_StudentId" FOREIGN KEY ("StudentId") REFERENCES "Users" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE TABLE "AttendanceHistories" (
        "Id" uuid NOT NULL,
        "AttendanceRecordId" uuid NOT NULL,
        "OldStatus" integer NOT NULL,
        "NewStatus" integer NOT NULL,
        "Reason" character varying(250) NOT NULL,
        "ChangedByUserId" uuid NOT NULL,
        "ChangedAtUtc" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_AttendanceHistories" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AttendanceHistories_AttendanceRecords_AttendanceRecordId" FOREIGN KEY ("AttendanceRecordId") REFERENCES "AttendanceRecords" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_AttendanceHistories_Users_ChangedByUserId" FOREIGN KEY ("ChangedByUserId") REFERENCES "Users" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_AttendanceHistories_AttendanceRecordId" ON "AttendanceHistories" ("AttendanceRecordId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_AttendanceHistories_ChangedByUserId" ON "AttendanceHistories" ("ChangedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_AttendanceQrSessions_ClassSessionId_IsOpen" ON "AttendanceQrSessions" ("ClassSessionId", "IsOpen");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_AttendanceQrSessions_QrToken" ON "AttendanceQrSessions" ("QrToken");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_AttendanceRecords_ClassSessionId_StudentId" ON "AttendanceRecords" ("ClassSessionId", "StudentId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_AttendanceRecords_StudentId" ON "AttendanceRecords" ("StudentId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_ClassEnrollments_CourseClassId_StudentId" ON "ClassEnrollments" ("CourseClassId", "StudentId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_ClassEnrollments_StudentId" ON "ClassEnrollments" ("StudentId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_ClassSessions_CourseClassId" ON "ClassSessions" ("CourseClassId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_CourseClasses_Code" ON "CourseClasses" ("Code");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_CourseClasses_LecturerId" ON "CourseClasses" ("LecturerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_CourseClasses_SubjectId" ON "CourseClasses" ("SubjectId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_OtpChallenges_Ticket" ON "OtpChallenges" ("Ticket");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE INDEX "IX_OtpChallenges_UserId_ExpiresAtUtc_IsUsed" ON "OtpChallenges" ("UserId", "ExpiresAtUtc", "IsUsed");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_Subjects_Code" ON "Subjects" ("Code");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_Users_Email" ON "Users" ("Email");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    CREATE UNIQUE INDEX "IX_Users_Username" ON "Users" ("Username");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261021041209_InitialCreate') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20261021041209_InitialCreate', '10.0.8');
    END IF;
END $EF$;
COMMIT;

