# 🔐 Environment Setup Guide

This guide will help you set up environment variables for secure API key management in your WaterFilterNet app.

## 📋 Prerequisites

Before setting up environment variables, you'll need accounts and API keys from:

1. **Stripe** (Required for payments)
2. **WooCommerce** (Optional - if using WooCommerce)
3. **Google Maps** (Optional - for address autocomplete)
4. **SendGrid** (Optional - for email notifications)

## 🚀 Quick Setup

### Step 1: Copy Environment Template

```bash
# Copy the example file to create your .env file
copy .env.example .env
```

### Step 2: Configure Stripe (Required)

1. **Sign up at**: https://dashboard.stripe.com
2. **Get your test keys**:
   - Go to Developers > API keys
   - Copy your **Publishable key** and **Secret key**
3. **Update .env file**:
   ```env
   STRIPE_PUBLISHABLE_KEY_WEB=pk_test_your_actual_key_here
   STRIPE_PUBLISHABLE_KEY_MOBILE=pk_test_your_actual_key_here
   STRIPE_SECRET_KEY=sk_test_your_actual_secret_here
   ```

### Step 3: Configure Optional Services

#### Google Maps (Optional)
1. **Get API key**: https://console.cloud.google.com
2. **Enable APIs**: Maps JavaScript API, Places API
3. **Add to .env**:
   ```env
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```

#### WooCommerce (Optional)
1. **In your WordPress admin**: WooCommerce > Settings > Advanced > REST API
2. **Generate keys** with Read/Write permissions
3. **Add to .env**:
   ```env
   WOOCOMMERCE_URL=https://your-store.com/wp-json/wc/v3
   WOOCOMMERCE_CONSUMER_KEY=ck_your_key_here
   WOOCOMMERCE_CONSUMER_SECRET=cs_your_secret_here
   ```

## 📁 File Structure

```
your_project/
├── .env                 # Your actual API keys (NEVER commit!)
├── .env.example         # Template file (safe to commit)
├── .gitignore          # Contains .env (prevents committing)
└── lib/services/
    └── environment_service.dart  # Loads environment variables
```

## ⚡ Usage in Code

The `EnvironmentService` automatically loads your environment variables:

```dart
final envService = EnvironmentService();

// Get Stripe key based on platform (web/mobile)
String stripeKey = envService.currentStripePublishableKey;

// Check if services are configured
bool isStripeReady = envService.isStripeConfigured;

// Get business configuration
double freeShipping = envService.freeShippingThreshold;
```

## 🔒 Security Best Practices

### ✅ DO:
- Keep `.env` in `.gitignore`
- Use different keys for development/production
- Rotate API keys regularly
- Use environment-specific keys

### ❌ DON'T:
- Commit `.env` file to git
- Share API keys in chat/email
- Use production keys in development
- Hard-code API keys in source code

## 🚀 Production Deployment

For production, update your `.env` file with live keys:

```env
# Production Stripe Keys
STRIPE_LIVE_PUBLISHABLE_KEY_WEB=pk_live_your_live_key_here
STRIPE_LIVE_PUBLISHABLE_KEY_MOBILE=pk_live_your_live_key_here
STRIPE_LIVE_SECRET_KEY=sk_live_your_live_secret_here
```

The app automatically uses live keys when built in release mode.

## 🐛 Troubleshooting

### Issue: "Stripe not configured"
**Solution**: Check your `.env` file has valid Stripe keys without placeholder text.

### Issue: Environment variables not loading
**Solutions**:
1. Ensure `.env` file is in project root
2. Check `.env` is listed in `pubspec.yaml` assets
3. Run `flutter clean && flutter pub get`

### Issue: Keys not working
**Solutions**:
1. Verify keys are correct in Stripe dashboard
2. Ensure no extra spaces around keys in `.env`
3. Check you're using test keys for development

## 📞 Support

If you encounter issues:

1. **Check logs** - The app prints configuration status at startup
2. **Verify keys** - Double-check your API keys in respective dashboards
3. **Environment** - Ensure `.env` file is properly formatted

## 🔄 Environment Status

The app will show you the configuration status at startup:

```
=== Environment Configuration ===
Environment loaded: true
Build mode: Debug
Platform: Web
App: WaterFilterNet v1.0.0
--- Service Status ---
Stripe configured: true ✅
WooCommerce configured: false ⚠️
Google Maps configured: false ⚠️
================================
```

This helps you quickly identify which services need configuration.

---

**🛡️ Remember**: Never commit your `.env` file to version control. Your API keys should remain secret!