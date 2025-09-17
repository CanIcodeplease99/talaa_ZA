#!/usr/bin/env bash
set -euo pipefail

# sanity
[ -d .git ] || { echo "Run this in your existing repo (must contain .git)"; exit 1; }

mk() { mkdir -p "$1"; }
wf() { mkdir -p "$(dirname "$1")"; printf "%s\n" "$2" > "$1"; }

echo "Scaffolding folders…"
mk backend/app/{controllers,models,services,adapters,workers}
mk backend/config backend/db/migrate backend/spec
mk superapp_flutter/lib/{ui,screens}
mk .github/workflows android_fastlane ios_fastlane store/{google_play,app_store} web/legal/za docs secrets

echo "Writing backend files…"
wf backend/Gemfile 'source "https://rubygems.org"
ruby "3.2.2"
gem "rails", "~> 7.1"
gem "pg"
gem "puma"
gem "sidekiq"
gem "redis"
gem "rack-cors"
gem "dotenv-rails"'

wf backend/config/routes.rb 'Rails.application.routes.draw do
  scope :v1 do
    resources :transfers, only: [:create, :show]
    get "quotes/fx", to: "quotes#fx"
    post "transfers/intl", to: "transfers#intl"
    post "transfers/offline/commit", to: "transfers#offline_commit"
    get  "rails/status", to: "rails_health#status"
    post "assistant/chat", to: "assistant#chat"
    post "business/apply", to: "business#apply"
    get  "business/status", to: "business#status"
    post "webhooks/stripe", to: "webhooks#stripe"
  end
end'

wf backend/app/controllers/transfers_controller.rb 'class TransfersController < ApplicationController
  def create
    render json: { id: SecureRandom.uuid, status: "sent", rail: params[:rail_hint] || "auto" }
  end
  def show; render json: { id: params[:id], status: "completed" }; end
  def intl; render json: { id: SecureRandom.uuid, status: "sent", rail: "intl" }; end
  def offline_commit; render json: { ok: true, queued: true }; end
end'

wf backend/app/controllers/quotes_controller.rb 'class QuotesController < ApplicationController
  def fx
    render json: { rate: 18.75, fee: 0.015, total_received: 1875.00, ttl_sec: 60 }
  end
end'

wf backend/app/controllers/rails_health_controller.rb 'class RailsHealthController < ApplicationController
  def status
    render json: { payshap: "healthy", ozow: "healthy", stitch: "degraded" }
  end
end'

wf backend/app/controllers/assistant_controller.rb 'class AssistantController < ApplicationController
  def chat; render json: { reply: "Hi! I can split bills, track spend, and route rails smartly.", sources: [] }; end
end'

wf backend/app/controllers/business_controller.rb 'class BusinessController < ApplicationController
  def apply; render json: { application_id: SecureRandom.uuid, status: "pending" }; end
  def status; render json: { status: "pending" }; end
end'

wf backend/app/controllers/webhooks_controller.rb 'class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  def stripe; head :ok; end
end'

wf backend/app/workers/settlement_worker.rb 'class SettlementWorker
  include Sidekiq::Worker
  def perform(transfer_id); Rails.logger.info "Settle #{transfer_id} via best ZA rail"; end
end'
wf backend/app/workers/intl_worker.rb 'class IntlWorker
  include Sidekiq::Worker
  def perform(transfer_id); Rails.logger.info "Fund via Stripe, FX via Wise/Thunes, then payout"; end
end'
wf backend/app/workers/rail_health_worker.rb 'class RailHealthWorker
  include Sidekiq::Worker
  def perform; Rails.logger.info "Poll PayShap/Ozow/Stitch health"; end
end'

wf backend/app/services/rails_health_service.rb 'class RailsHealthService
  def self.best(hint=nil); (hint || "payshap"); end
end'
wf backend/app/services/fx_service.rb 'class FxService
  def quote(src:"USD", dst:"ZAR", amount:100.0); { rate: 18.75, fee: 0.015, ttl_sec: 60 }; end
end'

wf backend/app/adapters/payshap_adapter.rb 'class PayshapAdapter
  def payout(msisdn:, amount_cents:, reference:nil); { ok: true, provider_id: "ps_#{SecureRandom.hex(6)}" }; end
end'
wf backend/app/adapters/ozow_adapter.rb 'class OzowAdapter
  def payout(msisdn:, amount_cents:, reference:nil); { ok: true, provider_id: "oz_#{SecureRandom.hex(6)}" }; end
end'
wf backend/app/adapters/stitch_adapter.rb 'class StitchAdapter
  def payout(msisdn:, amount_cents:, reference:nil); { ok: true, provider_id: "st_#{SecureRandom.hex(6)}" }; end
end'
wf backend/app/adapters/stripe_adapter.rb 'class StripeAdapter; end'
wf backend/app/adapters/wise_adapter.rb   'class WiseAdapter; end'
wf backend/app/adapters/thunes_adapter.rb 'class ThunesAdapter; end'

wf backend/db/migrate/20250917_create_core_tables.rb 'class CreateCoreTables < ActiveRecord::Migration[7.1]
  def change
    create_table :transfers, id: :uuid do |t|
      t.uuid :from_user; t.uuid :to_user; t.integer :amount_cents; t.string :currency; t.string :rail; t.string :status; t.jsonb :meta, default: {}
      t.timestamps
    end
    create_table :settlements, id: :uuid do |t|
      t.uuid :transfer_id; t.string :provider; t.string :status; t.jsonb :meta, default: {}
      t.timestamps
    end
    create_table :ledger_entries, id: :uuid do |t|
      t.uuid :user_id; t.integer :amount_cents; t.string :currency; t.string :direction; t.uuid :transfer_id; t.jsonb :meta, default: {}
      t.timestamps
    end
  end
end'

wf backend/.env.example 'RAILS_ENV=development
DATABASE_URL=postgres://postgres:postgres@localhost:5432/talaa_za_dev'

echo "Writing Flutter app…"
wf superapp_flutter/pubspec.yaml 'name: talaa_superapp
environment: { sdk: ">=3.4.0 <4.0.0" }
dependencies: { flutter: { sdk: flutter } }
flutter: { uses-material-design: true }'

wf superapp_flutter/lib/ui/theme.dart 'import "package:flutter/material.dart";
const royalBlue = Color(0xFF1A4CFF);
const indigo    = Color(0xFF3B0D91);
const softViolet= Color(0xFF9B6DFF);
const emerald   = Color(0xFF00C88C);
const bgDark    = Color(0xFF0D0D0F);
const bgLight   = Color(0xFFF7F8FA);
ThemeData talaaDark()=>ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bgDark,colorScheme:const ColorScheme.dark(primary:royalBlue,secondary:softViolet));
ThemeData talaaLight()=>ThemeData(brightness:Brightness.light,scaffoldBackgroundColor:bgLight,colorScheme:const ColorScheme.light(primary:royalBlue,secondary:softViolet));'

wf superapp_flutter/lib/ui/components.dart 'import "package:flutter/material.dart";
class PulseButton extends StatefulWidget{final String label; final VoidCallback onTap; const PulseButton({super.key,required this.label,required this.onTap}); @override State<PulseButton> createState()=>_PulseState();}
class _PulseState extends State<PulseButton> with SingleTickerProviderStateMixin{late final _c=AnimationController(vsync:this,duration:const Duration(seconds:2))..repeat(reverse:true);@override void dispose(){_c.dispose();super.dispose();}
  @override Widget build(BuildContext context){return ScaleTransition(scale:Tween(begin:0.98,end:1.02).animate(CurvedAnimation(parent:_c,curve:Curves.easeInOut)),child:FilledButton(onPressed:widget.onTap,child:Text(widget.label)));}}
class ObscuredAmount extends StatefulWidget{final String amount; const ObscuredAmount({super.key,required this.amount}); @override State<ObscuredAmount> createState()=>_OAState();}
class _OAState extends State<ObscuredAmount>{bool _r=false; @override Widget build(BuildContext c){return GestureDetector(onTap:()=>setState(()=>_r=!_r),child:Text(_r?widget.amount:"•••••",style:Theme.of(c).textTheme.headlineMedium));}}'

wf superapp_flutter/lib/screens/home.dart 'import "package:flutter/material.dart"; import "../ui/components.dart"; class HomeScreen extends StatelessWidget{const HomeScreen({super.key});
  @override Widget build(BuildContext c){return Scaffold(appBar: AppBar(title: const Text("Talaa")),body: Column(children:[
    // TODO: show only when offline
    // Container(color: Colors.indigo.shade50, padding: const EdgeInsets.all(8), child: const Text("Offline Mode — queued actions will sync later")),
    const SizedBox(height:12),
    Wrap(spacing:12,runSpacing:12,children:[
      PulseButton(label:"Send",onTap:(){}),
      FilledButton(onPressed:(){},child:const Text("Request")),
      FilledButton(onPressed:(){},child:const Text("QR Pay")),
      FilledButton(onPressed:(){},child:const Text("Split")),
      FilledButton(onPressed:(){},child:const Text("Discover")),
      FilledButton(onPressed:(){},child:const Text("Assistant")),
    ]),
    const SizedBox(height:16),
    const ListTile(title: Text("Recent Transactions")),
  ]));}}'

wf superapp_flutter/lib/screens/profile.dart 'import "package:flutter/material.dart"; import "../ui/components.dart";
class ProfileScreen extends StatelessWidget{const ProfileScreen({super.key});
  @override Widget build(BuildContext c){return Scaffold(appBar: AppBar(title: const Text("Profile")),body: ListView(children:[
    const ListTile(title: Text("Hide amounts (FaceID)"), subtitle: Text("Default ON")), const Divider(),
    const ListTile(title: Text("Virtual Card")), const ListTile(title: Text("Add to Apple/Google Wallet")),
    const Divider(), const ListTile(title: Text("Switch to Business Profile")),
  ]));}}'

wf superapp_flutter/lib/screens/business.dart 'import "package:flutter/material.dart";
class BusinessScreen extends StatelessWidget{const BusinessScreen({super.key});
  @override Widget build(BuildContext c){return Scaffold(appBar: AppBar(title: const Text("Business")),body: ListView(children:[
    const ListTile(title: Text("Merchant QR"), subtitle: Text("Show this to accept payments")),
    const ListTile(title: Text("Today\'s Sales"), trailing: Text("R 0.00")),
    const ListTile(title: Text("Insights"), subtitle: Text("Hourly sales chart (stub)")),
    const ListTile(title: Text("KYB Status"), trailing: Text("Pending")),
  ]));}}'

wf superapp_flutter/lib/screens/offline_qr.dart 'import "package:flutter/material.dart";
class OfflineQrScreen extends StatelessWidget{const OfflineQrScreen({super.key});
  @override Widget build(BuildContext c){return Scaffold(appBar: AppBar(title: const Text("Offline Mode")),body: ListView(children:[
    const ListTile(title: Text("Offline Secure"), subtitle: Text("Queued actions will sync later")),
    Card(child: ListTile(title: const Text("Queued transfer"), subtitle: const Text("Pending…"), trailing: Icon(Icons.schedule))),
  ]));}}'

wf superapp_flutter/lib/main.dart 'import "package:flutter/material.dart"; import "ui/theme.dart"; import "screens/home.dart";
void main()=>runApp(const TalaaApp());
class TalaaApp extends StatelessWidget{const TalaaApp({super.key});
  @override Widget build(BuildContext c){return MaterialApp(title:"Talaa",theme:talaaLight(),darkTheme:talaaDark(),home:const HomeScreen());}}'

echo "Workflows, store, legal…"
wf .github/workflows/release_android.yml 'name: release-android
on: { workflow_dispatch: {} }
jobs: { deploy: { runs-on: ubuntu-latest, steps: [
  { uses: "actions/checkout@v4" },
  { uses: "subosito/flutter-action@v2", with: { flutter-version: "3.22.0" } },
  { run: "cd superapp_flutter && flutter pub get && flutter build appbundle --release" }
]}}'
wf .github/workflows/release_ios.yml 'name: release-ios
on: { workflow_dispatch: {} }
jobs: { deploy: { runs-on: macos-latest, steps: [
  { uses: "actions/checkout@v4" },
  { uses: "subosito/flutter-action@v2", with: { flutter-version: "3.22.0" } }
]}}'

wf store/google_play/listing.json '{"packageName":"com.talaa.app","listings":{"en-US":{"title":"Talaa","shortDescription":"Instant, secure money for everyday life.","fullDescription":"Send, pay, split, and discover. Beautiful, private, and fast across multiple rails."}},"privacyPolicyUrl":"https://talaa.com/legal/za/privacy"}'
wf web/legal/za/privacy.html '<!doctype html><title>Talaa Privacy — ZA</title><h1>Privacy (ZA)</h1>'
wf web/legal/za/terms.html   '<!doctype html><title>Talaa Terms — ZA</title><h1>Terms (ZA)</h1>'

wf docs/RUN_LOCAL.md '# Backend
cd backend && bundle install && bin/rails db:create db:migrate && bin/rails s -p 3000

# Mobile
cd ../superapp_flutter && flutter pub get && flutter run --dart-define=API_BASE=http://localhost:3000'

echo "Done. Commit and push next."
