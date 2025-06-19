# 🔥 Firestore Setup Guide for CampusCart Messaging

## 📋 **Overview**

This guide will help you set up Firebase Firestore for the CampusCart messaging feature. The app uses Firestore to store conversations, messages, users, and products.

## 🚀 **Quick Setup Steps**

1. **Enable Firestore Database** in Firebase Console
2. **Create Required Indexes** (see below)
3. **Add Security Rules** (see below)
4. **Enable Authentication Methods**
5. **Test the Connection** using the app

## 🔍 **Required Firestore Indexes**

**IMPORTANT**: You need to create these indexes to avoid query errors.

### **Index 1: Conversations by Participants and Last Message Time**
**Collection**: `conversations`
**Fields**:
- `participants` (Array contains)
- `lastMessageTime` (Descending)
- `__name__` (Descending)

**Purpose**: For querying user conversations ordered by recent messages

**Quick Link**: [Create Index 1](https://console.firebase.google.com/v1/r/project/commad-line-cli/firestore/indexes?create_composite=ClVwcm9qZWN0cy9jb21tYWQtbGluZS1jbGkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2NvbnZlcnNhdGlvbnMvaW5kZXhlcy9fEAEaEAoMcGFydGljaXBhbnRzGAEaEwoPbGFzdE1lc3NhZ2VUaW1lEAIaDAoIX19uYW1lX18QAg)

### **Index 2: Conversations by Buyer, Seller, and Product**
**Collection**: `conversations`
**Fields**:
- `buyerId` (Ascending)
- `sellerId` (Ascending)
- `productId` (Ascending)

**Purpose**: For checking if a conversation already exists between buyer and seller for a specific product

### **How to Create Indexes Manually**:
1. Go to [Firebase Console](https://console.firebase.google.com/project/commad-line-cli)
2. Navigate to **Firestore Database → Indexes**
3. Click **"Create Index"**
4. Set up each index with the fields listed above
5. Wait for indexes to build (may take a few minutes)

**Note**: Indexes are required when you combine `where` clauses with `orderBy` clauses in Firestore queries.

## 📊 **Required Firestore Collections**

Your app uses the following Firestore collections:

### 1. **`conversations`** Collection
```javascript
{
  "conversationId": {
    "buyerId": "user_id_1",
    "sellerId": "user_id_2", 
    "productId": "product_id",
    "participants": ["user_id_1", "user_id_2"],
    "createdAt": "timestamp",
    "lastMessageId": "message_id",
    "lastMessageText": "Hello!",
    "lastMessageTime": "timestamp",
    "lastMessageSender": "user_id_1"
  }
}
```

### 2. **`conversations/{conversationId}/messages`** Subcollection
```javascript
{
  "messageId": {
    "sender": "user_id_1",
    "text": "Hello!",
    "timestamp": "timestamp"
  }
}
```

### 3. **`users`** Collection
```javascript
{
  "userId": {
    "uid": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "avatar": "https://...",
    "fcmToken": "fcm_token_here",
    "online": true
  }
}
```

### 4. **`products`** Collection
```javascript
{
  "productId": {
    "title": "Product Name",
    "price": 99.99,
    "description": "Product description",
    "image": "https://...",
    "images": ["https://...", "https://..."],
    "category": "Electronics",
    "condition": "New",
    "sellerId": "user_id",
    "active": true,
    "views": 0,
    "createdAt": "timestamp"
  }
}
```

### 5. **`wishlists`** Collection
```javascript
{
  "userId": {
    "products": ["product_id_1", "product_id_2"],
    "updatedAt": "timestamp"
  }
}
```

### 6. **`notifications`** Collection
```javascript
{
  "userId": {
    "notifications": [
      {
        "id": "notification_id",
        "type": "message|product|wishlist",
        "title": "New Message",
        "message": "You have a new message",
        "data": {},
        "read": false,
        "timestamp": "timestamp"
      }
    ]
  }
}
```

## 🔒 **Firestore Security Rules**

Copy and paste these security rules in your **Firebase Console → Firestore Database → Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is the owner
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Helper function to check if user is participant in conversation
    function isConversationParticipant(conversationData) {
      return isAuthenticated() && 
             request.auth.uid in conversationData.participants;
    }
    
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Products can be read by anyone, written by authenticated users
    match /products/{productId} {
      allow read: if true;
      allow write: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
        (request.auth.uid == resource.data.sellerId || 
         request.auth.uid in request.resource.data.sellerId);
      allow delete: if isAuthenticated() && 
        request.auth.uid == resource.data.sellerId;
    }
    
    // Conversations - users can only access conversations they're part of
    match /conversations/{conversationId} {
      allow read, write: if isAuthenticated() && 
        request.auth.uid in resource.data.participants;
      
      // Allow creating new conversations
      allow create: if isAuthenticated() && 
        request.auth.uid in request.resource.data.participants;
    }
    
    // Messages - users can only access messages in conversations they're part of
    match /conversations/{conversationId}/messages/{messageId} {
      allow read, write: if isAuthenticated() && 
        get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants[request.auth.uid] != null;
    }
    
    // Wishlists - users can only access their own wishlist
    match /wishlists/{userId} {
      allow read, write: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Notifications - users can only access their own notifications
    match /notifications/{userId} {
      allow read, write: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

## 🔐 **Authentication Setup**

### **Enable Authentication Methods**

1. Go to **Firebase Console → Authentication → Sign-in method**
2. Enable the following providers:

#### **Email/Password**
- ✅ Enable Email/Password
- ✅ Allow users to sign up
- ✅ Allow users to delete their account

#### **Google Sign-in**
- ✅ Enable Google
- ✅ Add your OAuth 2.0 Client ID (if needed)
- ✅ Configure authorized domains

## 🧪 **Testing the Setup**

### **Method 1: Automatic Test (Recommended)**
1. Run the app in debug mode:
   ```bash
   flutter run
   ```
2. The Firestore test will automatically run when the app starts
3. Check the console output for test results

### **Method 2: Manual Test Button**
1. Run the app:
   ```bash
   flutter run
   ```
2. On the sign-in screen, tap the **"Test Firestore Connection"** button
3. Check the console output for results

### **Expected Test Output**
```
🧪 Testing Firestore Connection...
✅ Firebase initialized successfully
📝 Testing write operation...
✅ Write test successful
📖 Testing read operation...
✅ Read test successful
📄 Document data: {timestamp: ..., status: connected, testTime: ...}
🧹 Cleaning up test data...
✅ Cleanup successful

📋 Testing required collections...
✅ Conversations collection accessible (0 documents)
✅ Users collection accessible (0 documents)
✅ Products collection accessible (0 documents)

🎉 All Firestore tests passed! Your setup is working correctly.
```

## 🔧 **Troubleshooting Common Issues**

### **1. "The query requires an index" errors**
**Cause**: Firestore needs composite indexes for complex queries
**Solution**: 
- Click the link provided in the error message to create the index automatically
- Or manually create the required indexes (see Required Firestore Indexes section above)
- Wait for indexes to build (may take a few minutes)

### **2. "Permission denied" errors**
**Cause**: Firestore security rules are blocking access
**Solution**: 
- Check that security rules are properly set
- Ensure user is authenticated
- Verify user has proper permissions

### **3. "No conversations found"**
**Cause**: Conversations collection doesn't exist or user not in participants
**Solution**:
- Check if conversations collection exists
- Verify participants array contains current user ID
- Check if user is properly authenticated

### **4. "Failed to send message"**
**Cause**: Conversation document doesn't exist or permission issues
**Solution**:
- Check if conversation document exists
- Verify user has permission to write to messages subcollection
- Check network connectivity

### **5. "Project not found"**
**Cause**: Firebase configuration is incorrect
**Solution**:
- Verify `firebase_options.dart` has correct project ID
- Check `google-services.json` and `GoogleService-Info.plist` files
- Ensure Firebase project is properly set up

### **6. "Authentication required"**
**Cause**: User is not signed in
**Solution**:
- Enable authentication methods in Firebase Console
- Check authentication flow in the app
- Verify user sign-in process

### **7. "Index building in progress"**
**Cause**: Indexes are still being created
**Solution**:
- Wait for indexes to finish building (check Firebase Console → Indexes)
- This can take 5-10 minutes for large collections
- The app will work once indexes are ready

## 📱 **App Testing Checklist**

Test each feature to ensure everything works:

- [ ] **User Authentication**
  - [ ] User can sign up with email/password
  - [ ] User can sign in with email/password
  - [ ] User can sign in with Google
  - [ ] User can sign out

- [ ] **Product Management**
  - [ ] User can create products
  - [ ] User can view products
  - [ ] User can edit their own products
  - [ ] User can delete their own products

- [ ] **Messaging Feature**
  - [ ] User can start a conversation with seller from product detail screen
  - [ ] User can start a conversation with seller from product card
  - [ ] User can send messages
  - [ ] User can receive messages
  - [ ] Messages appear in real-time
  - [ ] Conversation list shows recent messages
  - [ ] User cannot message themselves
  - [ ] Unauthenticated users are prompted to sign in

- [ ] **Wishlist Feature**
  - [ ] User can add products to wishlist
  - [ ] User can remove products from wishlist
  - [ ] User can view their wishlist

- [ ] **Notifications**
  - [ ] User receives push notifications
  - [ ] Notifications are stored in Firestore
  - [ ] User can mark notifications as read

## 💬 **Messaging Feature Details**

### **How to Message a Seller**

The app provides multiple ways to start a conversation with a seller:

#### **1. From Product Detail Screen**
- **Floating Action Button**: Large "Message Seller" button at bottom right
- **Seller Card**: "Chat with Seller" button in the seller information section

#### **2. From Product Cards**
- **Message Icon**: Small message icon on product cards in listings
- **Quick Access**: Allows messaging without opening the full product detail

#### **3. From Messages Screen**
- **Existing Conversations**: View and continue previous conversations
- **New Conversations**: Start new conversations from the messages list

### **Messaging Flow**

1. **User clicks messaging button**
2. **Authentication check**: If not signed in, shows sign-in prompt
3. **Self-message check**: Prevents users from messaging themselves
4. **Conversation creation**: Creates or finds existing conversation
5. **Chat screen**: Opens chat with seller and product context
6. **Real-time messaging**: Send and receive messages instantly

### **Features**

- ✅ **Real-time messaging** with Firestore
- ✅ **Product context** in conversations
- ✅ **User authentication** required
- ✅ **Self-message prevention**
- ✅ **Loading states** and error handling
- ✅ **Multiple access points** (detail screen, cards, messages)
- ✅ **Push notifications** for new messages

## 🔗 **Useful Links**

- [Firebase Console](https://console.firebase.google.com/project/commad-line-cli)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

## 📞 **Support**

If you encounter issues:

1. **Check the console output** for error messages
2. **Verify Firebase Console** settings
3. **Test with the provided test functions**
4. **Check network connectivity**
5. **Review security rules**

## 🎯 **Next Steps After Setup**

1. **Test the messaging feature** with multiple users
2. **Configure push notifications** for real-time messaging
3. **Set up Firebase Storage** for image uploads
4. **Configure Firebase Functions** for advanced features
5. **Set up monitoring and analytics**

---

**Project Details:**
- **Project ID**: `commad-line-cli`
- **Firebase Console**: https://console.firebase.google.com/project/commad-line-cli
- **App Name**: CampusCart
- **Platforms**: Android, iOS, Web 