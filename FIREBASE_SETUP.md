# Firebase Firestore Setup Guide for Campus Connect

## 📋 Required Firestore Collections & Documents

### 1. **users** Collection
Store basic user information and authentication details.

**Document Structure:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "Student",
  "approved": false,
  "avatarUrl": null,
  "createdAt": 1701475200000,
  "updatedAt": 1701475200000
}
```

**Fields:**
- `name` (string): User's full name
- `email` (string): User's email address
- `role` (string): One of ["Admin", "Student", "Teacher", "Parent"]
- `approved` (boolean): Whether admin has approved (for Student/Teacher)
- `avatarUrl` (string, nullable): User's profile picture URL
- `createdAt` (timestamp): Account creation time
- `updatedAt` (timestamp): Last update time

**Security Rules:**
```javascript
match /users/{userId} {
  allow read: if request.auth.uid == userId || resource.data.role == "Admin";
  allow create: if request.auth.uid == request.resource.data.userId;
  allow update: if request.auth.uid == userId || request.auth.token.role == "Admin";
}
```

---

### 2. **students** Collection
Store student-specific information.

**Document Structure:**
```json
{
  "userId": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "rollNumber": "STU001",
  "department": "Computer Science",
  "semester": "4",
  "attendance": 85.5,
  "gpa": 3.8,
  "eventsParticipated": 5,
  "courses": [
    {
      "id": "course1",
      "name": "Data Structures",
      "progress": 75,
      "credits": 4
    },
    {
      "id": "course2",
      "name": "Web Development",
      "progress": 60,
      "credits": 3
    }
  ],
  "parentEmail": "parent@example.com",
  "mentorId": "mentor123",
  "phoneNumber": "+1234567890",
  "address": "123 Main St, City",
  "emergencyContact": "+0987654321",
  "bloodGroup": "O+",
  "avatarUrl": null,
  "createdAt": 1701475200000,
  "updatedAt": 1701475200000
}
```

**Fields:**
- `userId` (string): Reference to user document ID
- `name` (string): Student's name
- `email` (string): Student's email
- `rollNumber` (string): Student ID/Roll number
- `department` (string): Department name
- `semester` (string): Current semester
- `attendance` (number): Attendance percentage (0-100)
- `gpa` (number): Grade Point Average
- `eventsParticipated` (number): Count of events attended
- `courses` (array): Array of course objects
- `parentEmail` (string): Parent's email for validation
- `mentorId` (string): Assigned mentor/teacher ID
- Additional fields for contact info, address, etc.

---

### 3. **schedule** Collection
Store class schedule and timetable information.

**Document Structure:**
```json
{
  "studentId": "user123",
  "date": "2024-01-15",
  "time": "10:00 AM - 11:30 AM",
  "subject": "Data Structures",
  "location": "Room 101, Building A",
  "instructor": "Dr. Smith",
  "createdAt": 1701475200000
}
```

**Fields:**
- `studentId` (string): Reference to student user ID
- `date` (string): Class date (YYYY-MM-DD format)
- `time` (string): Class time (HH:MM AM/PM format)
- `subject` (string): Course/subject name
- `location` (string): Classroom location
- `instructor` (string): Teacher's name

---

### 4. **notices** Collection
Store institution-wide notices and announcements.

**Document Structure:**
```json
{
  "title": "Examination Schedule Released",
  "description": "Final examinations will be held from Jan 20 to Feb 15. Please check the notice board for your exam schedule.",
  "date": 1701475200000,
  "category": "Academic",
  "priority": "High",
  "createdBy": "admin123",
  "createdAt": 1701475200000
}
```

**Fields:**
- `title` (string): Notice title
- `description` (string): Notice content
- `date` (timestamp): Notice publish date
- `category` (string): Category (Academic, Event, Maintenance, etc.)
- `priority` (string): Priority level (Low, Medium, High)
- `createdBy` (string): Admin user ID who created notice

---

### 5. **mentors** Collection (Teachers)
Store mentor/teacher information.

**Document Structure:**
```json
{
  "userId": "user456",
  "name": "Dr. Smith",
  "email": "smith@example.com",
  "department": "Computer Science",
  "designation": "Assistant Professor",
  "specialization": "Data Structures",
  "experience": "5 years",
  "isAvailable": true,
  "studentIds": ["user123", "user124", "user125"],
  "avatarUrl": null,
  "createdAt": 1701475200000,
  "updatedAt": 1701475200000
}
```

**Fields:**
- `userId` (string): Reference to user document ID
- `name` (string): Teacher's name
- `email` (string): Teacher's email
- `department` (string): Department
- `designation` (string): Job title
- `specialization` (string): Area of expertise
- `experience` (string): Years of experience
- `isAvailable` (boolean): Availability for mentoring
- `studentIds` (array): IDs of mentored students

---

### 6. **courses** Collection
Store course information.

**Document Structure:**
```json
{
  "name": "Data Structures",
  "code": "CS201",
  "department": "Computer Science",
  "semester": "4",
  "credits": 4,
  "instructorId": "mentor123",
  "description": "Learn fundamental data structures and algorithms",
  "syllabus": "https://example.com/syllabus.pdf",
  "capacity": 60,
  "enrolled": 45,
  "createdAt": 1701475200000
}
```

---

## 🔐 Firestore Security Rules

Add these rules to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
      allow create: if request.auth.uid != null;
      allow update: if request.auth.uid == userId;
      allow update: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
    
    // Students collection
    match /students/{studentId} {
      allow read: if request.auth.uid == studentId;
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Teacher";
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Parent";
      allow create: if request.auth.uid != null;
      allow update: if request.auth.uid == studentId;
      allow update: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
    
    // Schedules collection
    match /schedule/{scheduleId} {
      allow read: if request.auth.uid == resource.data.studentId;
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
    
    // Notices collection
    match /notices/{noticeId} {
      allow read: if request.auth.uid != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
    
    // Mentors collection
    match /mentors/{mentorId} {
      allow read: if request.auth.uid != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
    
    // Courses collection
    match /courses/{courseId} {
      allow read: if request.auth.uid != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "Admin";
    }
  }
}
```

---

## 📊 Creating Sample Data

### 1. Create Admin User (Manual in Firebase Console)

**Path:** `/users/{auto_id}`
```
name: "Admin"
email: "admin@malabarcollege.com"
role: "Admin"
approved: true
avatarUrl: null
createdAt: (current timestamp)
updatedAt: (current timestamp)
```

> **Note:** The app uses hardcoded admin credentials, so you don't need to create admin in Firestore for login. However, creating the document is good for record-keeping.

### 2. Create Sample Student

Register through the app:
1. Click "Register"
2. Select "Student" role
3. Fill in name, email, password
4. This automatically creates:
   - Document in `/users/{uid}` with `approved: false`
   - Document in `/students/{uid}` with default values

### 3. Create Sample Teacher

Register through the app:
1. Click "Register"
2. Select "Teacher" role
3. Fill in name, email, password
4. This automatically creates:
   - Document in `/users/{uid}` with `approved: false`
   - Document in `/mentors/{uid}` with teacher data

### 4. Create Sample Parent

1. First create a student (as above)
2. Get the student's email (e.g., student@example.com)
3. Update student document: add `parentEmail: "parent@example.com"`
4. Register as Parent:
   - Click "Register"
   - Select "Parent" role
   - Use email: `parent@example.com`
   - The app validates against the student's `parentEmail` field

### 5. Add Sample Schedule

**Path:** `/schedule/{auto_id}`
```
studentId: "{student_uid}"
date: "2024-01-15"
time: "10:00 AM - 11:30 AM"
subject: "Data Structures"
location: "Room 101"
instructor: "Dr. Smith"
createdAt: (current timestamp)
```

### 6. Add Sample Notice

**Path:** `/notices/{auto_id}`
```
title: "Semester Examinations Schedule"
description: "Final examinations will begin on January 20th..."
date: (current timestamp)
category: "Academic"
priority: "High"
createdBy: "admin_uid"
createdAt: (current timestamp)
```

---

## 🔍 Database Indexes

Firestore will automatically suggest indexes as you query. Some recommended indexes:

1. **schedule collection:**
   - studentId (Ascending)
   - time (Ascending)

2. **notices collection:**
   - date (Descending)

3. **students collection:**
   - parentEmail (Ascending) - for parent validation

4. **users collection:**
   - role (Ascending)
   - approved (Ascending)

---

## ✅ Verification Checklist

- [ ] Create all 6 collections
- [ ] Add security rules
- [ ] Create sample admin user (optional, hardcoded login works)
- [ ] Test student registration
- [ ] Test teacher registration
- [ ] Test parent registration with linked student
- [ ] Admin approves a student
- [ ] Student logs in and views home screen
- [ ] Admin can view and manage users
- [ ] Add sample notices
- [ ] Add sample schedule for a student
- [ ] Student home screen displays live data

---

## 🚀 Quick Start

1. **Open Firebase Console** → Select your project
2. **Go to Firestore Database** → Create collections
3. **Create the 6 collections** as outlined above
4. **Set security rules** (copy-paste from above)
5. **Test the app**:
   ```bash
   flutter run
   ```
6. **Register** a student account
7. **Approve** in admin panel
8. **Login** and verify data displays

---

## 📱 App Testing Flow

1. **Admin Login:**
   - Email: `admin@malabarcollege.com`
   - Password: `admin123`
   - Access: Admin Dashboard

2. **Student Flow:**
   - Register with Student role
   - Admin approves account
   - Login with same credentials
   - View student home screen with Firestore data

3. **Parent Flow:**
   - Update a student document with `parentEmail`
   - Register with that email as Parent
   - After approval, can login and view student info

---

**Your Firestore is now ready! Start testing with the app.** 🎉
