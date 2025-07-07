# Admin Dashboard Features

## Overview
The admin dashboard now includes enhanced functionality for managing users, listings, and reports.

## New Features

### 1. Users Management
- **Total Users Stat**: Click on the "Total Users" card in the admin dashboard to view all users
- **Users List Screen**: Shows all users with their active listings
- **User Details**: Each user shows:
  - Profile information (name, email, join date)
  - Account status (active, banned, suspended)
  - Active listings count
  - Expandable view to see all active listings

### 2. Listing Analytics
- **Active Listings Stat**: Click on the "Active Listings" card to view analytics
- **Analytics Screen**: Shows a graph of all active listings over time
- **Time Period Selection**: Choose between 7 days, 30 days, 90 days, or 1 year
- **Statistics**: Displays:
  - Total active listings
  - Listings created this week/month
  - Average views per listing
- **Interactive Chart**: Line chart showing listing creation trends

### 3. Enhanced Reports Management
- **Reports Collection**: View all reports in a comprehensive list
- **Report Actions**:
  - **Ignore**: Mark report as ignored (changes status to "ignored")
  - **Delete**: Permanently remove report from database
- **Report Details**: Each report shows:
  - Product title and reason
  - Reporter information
  - Report date and status
  - Visual status indicators with colors and icons

## Navigation
- Admin Dashboard → Click "Total Users" → Users List Screen
- Admin Dashboard → Click "Active Listings" → Listing Analytics Screen
- Admin Dashboard → Click "Reports" → All Reports Screen

## Technical Implementation
- **Dependencies**: Added `fl_chart: ^0.68.0` for chart visualization
- **New Screens**: 
  - `UsersListScreen` - `/users-list`
  - `ListingAnalyticsScreen` - `/listing-analytics`
- **Enhanced Screens**:
  - `AllReportsScreen` - Added ignore/delete functionality
  - `AdminDashboardScreen` - Updated stats loading and navigation

## Database Collections Used
- `users` - User information and status
- `products` - Product listings and analytics data
- `reports` - User reports with status tracking

## Status Colors
- **Pending**: Orange
- **Resolved**: Green
- **Ignored**: Grey
- **Investigating**: Blue
- **Active Users**: Green
- **Banned Users**: Red
- **Suspended Users**: Orange 