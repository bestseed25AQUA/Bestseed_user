# Best Deals Feature - Flutter Integration Guide

## When Backend Gives You 2 API Endpoints, How Do You Plan?

Backend gave us:
```
GET  /farmer/best-deals        --> Returns list of all best deals
GET  /farmer/best-deals/{id}   --> Returns single deal detail
```

### Step 1: Ask Backend for Sample JSON Response

Before writing any code, ask the backend developer: "Give me sample JSON response for both APIs."

**List API Response** (`GET /farmer/best-deals`):
```json
{
  "status": true,
  "message": "Best deals fetched successfully",
  "data": [
    {
      "id": 1,
      "title": "Fish Foods",
      "subtitle": "Gutwell, Vibract",
      "media_path": "https://example.com/uploads/best_deals/image1.jpg",
      "media_type": "image",
      "media_files": [
        "https://example.com/uploads/best_deals/image1.jpg",
        "https://example.com/uploads/best_deals/image2.jpg"
      ],
      "media_types": ["image", "image"],
      "created_at": "19-02-2026"
    },
    {
      "id": 2,
      "title": "Pond Supplies",
      "subtitle": "Premium Quality",
      "media_path": "https://example.com/uploads/best_deals/image3.jpg",
      ...
    }
  ]
}
```

**Detail API Response** (`GET /farmer/best-deals/1`):
```json
{
  "status": true,
  "message": "Best deal details fetched successfully",
  "data": {
    "id": 1,
    "title": "Fish Foods",
    "subtitle": "Gutwell, Vibract",
    "description": "<h2>Product Details</h2><p>High quality fish food...</p>",
    "media_path": "https://example.com/uploads/best_deals/image1.jpg",
    "media_files": ["..."],
    "media_types": ["image", "image"],
    "call_number": "tel:9876543210",
    "whatsapp_number": "https://wa.me/9876543210",
    "created_at": "19-02-2026"
  }
}
```

### Step 2: Look at the JSON and Decide What You Need

| Question | Answer |
|----------|--------|
| List API returns array of items? | Yes -> We need `ListView.builder` |
| Detail API returns single object? | Yes -> We need `SingleChildScrollView` |
| Detail has description text? | Yes -> Simple `Text()` or `HtmlWidget()` |
| Detail has action buttons (call/whatsapp)? | Yes -> `bottomNavigationBar` with buttons |
| Items have images? | Yes -> `Image.network` or `MediaCarouselWidget` |

---

## Step 3: Folder Structure - What Files to Create

For ANY feature with list + detail screens, you always need these 5 files:

```
lib/app/best_deals/
    |
    ├── model/
    |   ├── best_deals_list_model.dart      -- Parse LIST API JSON
    |   └── best_deal_detail_model.dart     -- Parse DETAIL API JSON
    |
    ├── controller/
    |   └── best_deals_controller.dart      -- Call APIs + hold data
    |
    └── view/
        ├── best_deals_screen.dart          -- LIST screen (Screen 1)
        └── best_deal_detail_screen.dart    -- DETAIL screen (Screen 2)
```

**Rule:** 1 endpoint = 1 model. 2 endpoints = 2 models. Controller handles ALL endpoints for this feature.

---

## Step 4: Build Order (ALWAYS follow this sequence)

```
Model first --> Controller second --> Screen last

Why? Because:
- Screen NEEDS Controller (to get data)
- Controller NEEDS Model (to parse JSON)
- Model NEEDS nothing (it just parses JSON)

So build bottom-up: Model -> Controller -> Screen
```

---

## FILE 1: List Model (`best_deals_list_model.dart`)

### What does it do?
Converts the LIST API JSON response into Dart objects so we can use `deal.title`, `deal.id`, etc. instead of `json["title"]`.

### How to think about it?
Look at the JSON response and create a Dart class that mirrors it.

```
JSON Structure:                     Dart Classes:
{                                   BestDealsListModel
  "status": true,                     - status (bool)
  "message": "...",                   - message (String)
  "data": [                           - data (List<BestDealItem>)
    {                               BestDealItem
      "id": 1,                        - id (int)
      "title": "Fish Foods",          - title (String)
      "subtitle": "Gutwell",          - subtitle (String)
      "media_path": "...",             - mediaPath (String)
      "media_files": [...],            - mediaFiles (List<String>)
      "media_types": [...]             - mediaTypes (List<String>)
    }
  ]
}
```

### Actual Code:
```dart
import 'dart:convert';

// Helper function (optional, useful for quick parsing)
BestDealsListModel bestDealsListModelFromJson(String str) =>
    BestDealsListModel.fromJson(json.decode(str));

// OUTER wrapper class - matches the full JSON response
class BestDealsListModel {
  bool? status;
  String? message;
  List<BestDealItem>? data;        // "data" is an ARRAY -> List<BestDealItem>

  BestDealsListModel({this.status, this.message, this.data});

  factory BestDealsListModel.fromJson(Map<String, dynamic> json) =>
      BestDealsListModel(
        status: json["status"],
        message: json["message"],
        // Convert each item in the array to a BestDealItem object
        data: json["data"] == null
            ? []
            : List<BestDealItem>.from(
                json["data"]!.map((x) => BestDealItem.fromJson(x)),
              ),
      );
}

// INNER class - matches each object inside the "data" array
class BestDealItem {
  int? id;
  String? title;
  String? subtitle;
  String? mediaType;
  String? mediaPath;
  List<String>? mediaFiles;
  List<String>? mediaTypes;
  String? createdAt;

  BestDealItem({
    this.id, this.title, this.subtitle,
    this.mediaType, this.mediaPath,
    this.mediaFiles, this.mediaTypes, this.createdAt,
  });

  factory BestDealItem.fromJson(Map<String, dynamic> json) {
    // Handle media_files (can be array or single path)
    List<String>? files;
    List<String>? types;
    if (json["media_files"] != null && json["media_files"] is List) {
      files = List<String>.from(json["media_files"].map((x) => x.toString()));
      types = json["media_types"] != null && json["media_types"] is List
          ? List<String>.from(json["media_types"].map((x) => x.toString()))
          : [];
    } else if (json["media_path"] != null &&
        json["media_path"].toString().isNotEmpty) {
      files = [json["media_path"].toString()];
      types = [json["media_type"]?.toString() ?? 'image'];
    }

    return BestDealItem(
      id: json["id"],
      title: json["title"],
      subtitle: json["subtitle"],
      mediaType: json["media_type"],
      mediaPath: json["media_path"],
      mediaFiles: files,
      mediaTypes: types,
      createdAt: json["created_at"],
    );
  }
}
```

### Key Points:
- JSON key `"media_path"` -> Dart field `mediaPath` (camelCase)
- Everything is nullable (`String?`, `int?`) because API might not send some fields
- `factory fromJson()` is the constructor that reads JSON keys and creates the object
- For the LIST model, `data` is `List<BestDealItem>` (array of items)

---

## FILE 2: Detail Model (`best_deal_detail_model.dart`)

### What does it do?
Same as list model, but for the DETAIL API. Detail has extra fields: `description`, `call_number`, `whatsapp_number`.

### How is it different from List Model?

```
List Model "data":  [ { item1 }, { item2 } ]   --> List<BestDealItem>  (ARRAY)
Detail Model "data": { single_item }            --> BestDealDetail      (SINGLE OBJECT)
```

### Actual Code:
```dart
import 'dart:convert';

BestDealDetailModel bestDealDetailModelFromJson(String str) =>
    BestDealDetailModel.fromJson(json.decode(str));

class BestDealDetailModel {
  bool? status;
  String? message;
  BestDealDetail? data;    // NOT a List! Single object because detail = 1 item

  BestDealDetailModel({this.status, this.message, this.data});

  factory BestDealDetailModel.fromJson(Map<String, dynamic> json) =>
      BestDealDetailModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : BestDealDetail.fromJson(json["data"]),  // Single object, not array
      );
}

class BestDealDetail {
  int? id;
  String? title;
  String? subtitle;
  String? description;         // EXTRA field (not in list)
  String? mediaType;
  String? mediaPath;
  List<String>? mediaFiles;
  List<String>? mediaTypes;
  String? callNumber;          // EXTRA field (not in list)
  String? whatsappNumber;      // EXTRA field (not in list)
  String? createdAt;

  BestDealDetail({
    this.id, this.title, this.subtitle, this.description,
    this.mediaType, this.mediaPath, this.mediaFiles, this.mediaTypes,
    this.callNumber, this.whatsappNumber, this.createdAt,
  });

  factory BestDealDetail.fromJson(Map<String, dynamic> json) {
    // Same media handling as list model
    List<String>? files;
    List<String>? types;
    if (json["media_files"] != null && json["media_files"] is List) {
      files = List<String>.from(json["media_files"].map((x) => x.toString()));
      types = json["media_types"] != null && json["media_types"] is List
          ? List<String>.from(json["media_types"].map((x) => x.toString()))
          : [];
    } else if (json["media_path"] != null &&
        json["media_path"].toString().isNotEmpty) {
      files = [json["media_path"].toString()];
      types = [json["media_type"]?.toString() ?? 'image'];
    }

    return BestDealDetail(
      id: json["id"],
      title: json["title"],
      subtitle: json["subtitle"],
      description: json["description"],           // Extra
      mediaType: json["media_type"],
      mediaPath: json["media_path"],
      mediaFiles: files,
      mediaTypes: types,
      callNumber: json["call_number"],            // Extra
      whatsappNumber: json["whatsapp_number"],    // Extra
      createdAt: json["created_at"],
    );
  }
}
```

---

## FILE 3: Controller (`best_deals_controller.dart`)

### What does it do?
- Calls the API endpoints
- Stores the response data in observable variables
- UI listens to these variables and rebuilds automatically

### How to think about it?

```
Controller is the BRAIN:
  1. Screen says: "I need data"
  2. Controller calls API endpoint
  3. API returns JSON
  4. Controller converts JSON -> Model (using fromJson)
  5. Controller stores Model in observable variable (.obs)
  6. Screen automatically rebuilds because it's watching with Obx()
```

### Data Flow Diagram:
```
Screen (UI)                    Controller                    API Server
    |                              |                              |
    |--- Get.put(Controller) ----->|                              |
    |                              |--- onInit() called --------->|
    |                              |--- fetchList() ------------->|
    |                              |                              |
    |                              |<-- JSON response ------------|
    |                              |                              |
    |                              |-- json.decode(response) ---->|
    |                              |-- Model.fromJson(data) ----->|
    |                              |-- bestDealsData.value = model|
    |                              |                              |
    |<-- Obx() auto-rebuilds -----|                              |
    |   (shows data on screen)     |                              |
```

### Actual Code:
```dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/best_deals/model/best_deal_detail_model.dart';
import 'package:seedsuser/app/best_deals/model/best_deals_list_model.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BestDealsController extends GetxController {
  // ---------- OBSERVABLE VARIABLES ----------
  // .obs makes them reactive - UI auto-updates when value changes
  var isLoading = true.obs;                                    // Loading state for list
  var isDetailLoading = true.obs;                              // Loading state for detail
  Rx<BestDealsListModel?> bestDealsData = Rx<BestDealsListModel?>(null);   // List data
  Rx<BestDealDetailModel?> bestDealDetail = Rx<BestDealDetailModel?>(null); // Detail data

  // ---------- LIFECYCLE ----------
  @override
  void onInit() {
    super.onInit();
    fetchList();   // Auto-fetch list when controller is created
  }

  // ---------- API CALL 1: Fetch List ----------
  Future<void> fetchList() async {
    try {
      isLoading.value = true;                              // Show shimmer/loading

      // Step 1: Call API
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals",
        headers: await buildHeader(),                      // Auth token etc.
      );

      // Step 2: Check if success
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Step 3: Decode JSON string -> Map
        final data = json.decode(response.body);
        // Step 4: Map -> Model object (using fromJson)
        bestDealsData.value = BestDealsListModel.fromJson(data);
        // Step 5: UI auto-updates because bestDealsData is .obs
      } else {
        CustomToast.error("Failed to fetch Best Deals");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;                             // Hide shimmer/loading
    }
  }

  // ---------- API CALL 2: Fetch Detail ----------
  Future<void> fetchDetail(String id) async {
    try {
      isDetailLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals/$id",  // ID in URL
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        bestDealDetail.value = BestDealDetailModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch details");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isDetailLoading.value = false;
    }
  }
}
```

### Key Concepts:
| Concept | What it does |
|---------|-------------|
| `.obs` | Makes variable reactive. When value changes, UI rebuilds |
| `Rx<Model?>` | Reactive wrapper for nullable model |
| `onInit()` | Called automatically when controller is created (like initState) |
| `getRequest()` | Our project's HTTP GET helper (from network_utils.dart) |
| `buildHeader()` | Builds auth headers with token |
| `json.decode()` | Converts JSON string -> Dart Map |
| `Model.fromJson()` | Converts Dart Map -> Model object |

---

## FILE 4: List Screen (`best_deals_screen.dart`)

### What does it do?
Shows a scrollable list of best deal cards. Each card shows image + title + subtitle.

### How to decide: ListView vs GridView vs SingleChildScrollView?

```
Decision Tree:
  |
  |-- How many items? Unknown/dynamic number from API?
  |     |-- YES --> Use ListView.builder (builds items lazily, good for performance)
  |     |-- NO (fixed few items) --> Use SingleChildScrollView + Column
  |
  |-- Items in a grid (2-3 columns)?
  |     |-- YES --> Use GridView.builder
  |     |-- NO (full width, stacked vertically) --> Use ListView.builder
  |
  |-- Single page with lots of different content (not repeating)?
  |     |-- YES --> Use SingleChildScrollView + Column
  |     |-- NO --> Use ListView.builder

For Best Deals LIST: Unknown number of items, full width, stacked vertically
  --> ListView.builder
```

### Screen Structure:
```
Scaffold
  |
  ├── AppBar (CustomAppBar)
  |     ├── Back button (CircleAvatar + IconButton)
  |     └── Title: "Best Deals"
  |
  └── body: Obx()    <-- Reactive wrapper, rebuilds when data changes
        |
        ├── IF loading -> Show Shimmer
        ├── IF empty   -> Show "No Best Deals Available"
        └── IF has data -> RefreshIndicator
                            └── ListView.builder
                                  └── For each deal:
                                        GestureDetector (onTap -> detail screen)
                                          └── Column
                                                ├── MiniMediaCarousel (image)
                                                ├── Title (Text, bold)
                                                └── Subtitle (Text, grey)
```

### Actual Code:
```dart
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/controller/best_deals_controller.dart';
import 'package:seedsuser/app/best_deals/view/best_deal_detail_screen.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';

class BestDealsScreen extends StatefulWidget {
  const BestDealsScreen({super.key});

  @override
  State<BestDealsScreen> createState() => _BestDealsScreenState();
}

class _BestDealsScreenState extends State<BestDealsScreen> {
  // Get.put() creates the controller AND triggers onInit() -> fetchList()
  final controller = Get.put(BestDealsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Best Deals',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Obx listens to controller's .obs variables
      // When isLoading or bestDealsData changes, this rebuilds
      body: Obx(() {
        // STATE 1: Loading
        if (controller.isLoading.value) {
          return _buildShimmer();
        }

        // STATE 2: Empty
        final deals = controller.bestDealsData.value?.data;
        if (deals == null || deals.isEmpty) {
          return Center(child: Text('No Best Deals Available'));
        }

        // STATE 3: Has Data
        return RefreshIndicator(
          onRefresh: () => controller.fetchList(),  // Pull to refresh
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deals.length,           // Number of items from API
            itemBuilder: (context, index) {
              final deal = deals[index];       // Get each BestDealItem

              return GestureDetector(
                onTap: () {
                  // Navigate to detail screen, pass required data
                  Get.to(() => BestDealDetailScreen(
                    id: deal.id.toString(),
                    title: deal.title ?? '',
                    subtitle: deal.subtitle ?? '',
                    imageUrl: deal.mediaPath ?? '',
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MiniMediaCarousel(
                          mediaUrls: deal.mediaFiles ?? [deal.mediaPath ?? ''],
                          mediaTypes: deal.mediaTypes ?? [deal.mediaType ?? 'image'],
                          height: 180,
                          borderRadius: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title
                      Text(deal.title ?? '',
                        style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // Subtitle (only if exists)
                      if (deal.subtitle != null && deal.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(deal.subtitle!,
                          style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // Shimmer = skeleton loading animation while API loads
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,  // Show 4 fake skeleton cards
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: [
              Container(height: 180, decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
              )),
              const SizedBox(height: 10),
              Container(height: 16, width: 150, decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(6),
              )),
            ],
          ),
        );
      },
    );
  }
}
```

---

## FILE 5: Detail Screen (`best_deal_detail_screen.dart`)

### What does it do?
Shows full detail of one deal: big image carousel, title, subtitle, HTML description, and Enquiry/WhatsApp buttons at bottom.

### How to decide the scroll widget?

```
This is a SINGLE page with different content sections (not repeating items):
  - Image carousel
  - Title
  - Subtitle
  - Description (can be long)

NOT a list of same items --> Use SingleChildScrollView + Column (NOT ListView)

Also has FIXED buttons at bottom --> Use bottomNavigationBar
```

### Screen Structure:
```
Scaffold
  |
  ├── AppBar (CustomAppBar with title)
  |
  ├── body: Column
  |     └── Obx()
  |           └── Expanded
  |                 └── SingleChildScrollView  (scrollable content)
  |                       └── Column
  |                             ├── MediaCarouselWidget (big images/videos)
  |                             ├── Title (Text, bold)
  |                             ├── Subtitle (Text, grey)
  |                             └── Description (HtmlWidget for formatted text)
  |                                  OR Shimmer (while loading)
  |
  └── bottomNavigationBar: Obx()    (FIXED at bottom, doesn't scroll)
        └── Row
              ├── Enquiry Button (ElevatedButton.icon -> phone call)
              └── WhatsApp Button (OutlinedButton.icon -> whatsapp)
```

### Why pass data through constructor?

```dart
// When navigating from list screen:
Get.to(() => BestDealDetailScreen(
  id: deal.id.toString(),       // Needed to call detail API
  title: deal.title ?? '',      // Show immediately while API loads
  subtitle: deal.subtitle ?? '',// Show immediately while API loads
  imageUrl: deal.mediaPath ?? '',// Show immediately while API loads
));
```

**Why?** When user taps a card, the detail screen opens INSTANTLY with title + image from the list.
Then `initState()` calls `fetchDetail(id)` in background. When API responds, `Obx()` updates
the UI with full data (description, call number, etc). User never sees a blank screen!

### The initState + fetchDetail flow:
```
User taps card on list screen
  |
  v
Get.to(BestDealDetailScreen(id: "1", title: "Fish Foods", ...))
  |
  v
Detail screen opens -> Shows title & image from constructor (INSTANT)
  |
  v
initState() runs -> controller.fetchDetail("1")
  |
  v
API call in background -> isDetailLoading = true -> Shimmer shows for description
  |
  v
API responds -> bestDealDetail.value = parsed data -> isDetailLoading = false
  |
  v
Obx() rebuilds -> Description shows, buttons become active
```

### Actual Code:
```dart
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/controller/best_deals_controller.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class BestDealDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  const BestDealDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  State<BestDealDetailScreen> createState() => _BestDealDetailScreenState();
}

class _BestDealDetailScreenState extends State<BestDealDetailScreen> {
  // Get.put() reuses existing controller (already created in list screen)
  final controller = Get.put(BestDealsController());

  @override
  void initState() {
    super.initState();
    // Fetch full detail from API using the ID passed from list screen
    controller.fetchDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        backgroundColor: Colors.blue[800],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.title,   // Show title immediately from constructor
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),

      // SCROLLABLE CONTENT
      body: Column(
        children: [
          Obx(() {
            final data = controller.bestDealDetail.value?.data;

            // Use API data if loaded, otherwise use constructor data
            final mediaUrls =
                (data?.mediaFiles != null && data!.mediaFiles!.isNotEmpty)
                    ? data.mediaFiles!
                    : [widget.imageUrl];

            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image/Video Carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MediaCarouselWidget(
                        mediaUrls: mediaUrls,
                        mediaTypes: mediaTypes,
                        borderRadius: 16,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Title (from API or constructor fallback)
                    Text(
                      data?.title ?? widget.title,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Subtitle
                    if ((data?.subtitle ?? widget.subtitle).isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(data?.subtitle ?? widget.subtitle,
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
                      ),
                    ],

                    const SizedBox(height: 12.0),

                    // Description - Shows SHIMMER while loading, HTML when loaded
                    Builder(
                      builder: (context) {
                        if (controller.isDetailLoading.value) {
                          return _descriptionShimmer();
                        }
                        // HtmlWidget renders HTML tags properly (headings, paragraphs, bold, etc.)
                        return HtmlWidget(
                          data?.description ?? '',
                          textStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),

      // FIXED BOTTOM BUTTONS (don't scroll with content)
      bottomNavigationBar: Obx(() {
        final data = controller.bestDealDetail.value?.data;
        final callNum = data?.callNumber ?? '';
        final whatsappUrl = data?.whatsappNumber ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 30),
          child: Row(
            children: [
              // Enquiry Button -> Makes phone call
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: callNum.isNotEmpty
                      ? () => _makePhoneCall(callNum)
                      : null,    // null = button disabled (greyed out)
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text('Enquiry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2196F3),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // WhatsApp Button -> Opens WhatsApp
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: whatsappUrl.isNotEmpty
                      ? () => _launchWhatsApp(whatsappUrl)
                      : null,
                  icon: Image.asset('assets/images/whatsApp.png', height: 20, width: 20),
                  label: Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Phone call using url_launcher
  Future<void> _makePhoneCall(String callUrl) async {
    final Uri launchUri = Uri.parse(callUrl);  // "tel:9876543210"
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // WhatsApp using url_launcher
  Future<void> _launchWhatsApp(String whatsappUrl) async {
    final Uri launchUri = Uri.parse(whatsappUrl);  // "https://wa.me/9876543210"
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }
}
```

---

## COMPLETE DATA FLOW - End to End

```
==========================================================================
STEP 1: User taps "Best Deals" on Home Screen
==========================================================================

all_screen.dart:
  onTap: () => Get.to(() => BestDealsScreen())

==========================================================================
STEP 2: BestDealsScreen opens -> Controller created
==========================================================================

best_deals_screen.dart:
  final controller = Get.put(BestDealsController());
  // Get.put() creates controller -> onInit() runs -> fetchList() runs

==========================================================================
STEP 3: Controller calls LIST API
==========================================================================

best_deals_controller.dart:
  fetchList() {
    isLoading.value = true;    // UI shows shimmer
    response = await getRequest("/farmer/best-deals");
    data = json.decode(response.body);
    bestDealsData.value = BestDealsListModel.fromJson(data);
    isLoading.value = false;   // UI shows list
  }

==========================================================================
STEP 4: JSON -> Model conversion
==========================================================================

API returns:
  { "status": true, "data": [ {"id":1, "title":"Fish Foods"}, {...} ] }
                                    |
                                    v
best_deals_list_model.dart:
  BestDealsListModel.fromJson(json)
    -> status = true
    -> data = [ BestDealItem(id:1, title:"Fish Foods"), ... ]

==========================================================================
STEP 5: UI rebuilds (Obx detects change)
==========================================================================

best_deals_screen.dart:
  Obx(() {
    // This entire block re-runs when bestDealsData changes
    final deals = controller.bestDealsData.value?.data;
    return ListView.builder(
      itemCount: deals.length,
      itemBuilder: (ctx, i) => Card(deals[i].title, deals[i].mediaPath, ...)
    );
  })

==========================================================================
STEP 6: User taps a card -> Navigate to Detail
==========================================================================

best_deals_screen.dart:
  onTap: () => Get.to(() => BestDealDetailScreen(
    id: "1", title: "Fish Foods", subtitle: "Gutwell", imageUrl: "..."
  ));

==========================================================================
STEP 7: Detail screen opens -> Fetches detail API
==========================================================================

best_deal_detail_screen.dart:
  initState() {
    controller.fetchDetail(widget.id);   // "1"
  }

  // Meanwhile, screen already shows title + image from constructor
  // Description area shows shimmer loading

==========================================================================
STEP 8: Controller calls DETAIL API
==========================================================================

best_deals_controller.dart:
  fetchDetail("1") {
    isDetailLoading.value = true;    // Shimmer for description
    response = await getRequest("/farmer/best-deals/1");
    data = json.decode(response.body);
    bestDealDetail.value = BestDealDetailModel.fromJson(data);
    isDetailLoading.value = false;   // Show description + enable buttons
  }

==========================================================================
STEP 9: Detail UI rebuilds with full data
==========================================================================

best_deal_detail_screen.dart:
  Obx(() {
    final data = controller.bestDealDetail.value?.data;
    // Now data has: description, callNumber, whatsappNumber
    // Description: HtmlWidget renders formatted HTML
    // Buttons: Enquiry + WhatsApp become active
  })

==========================================================================
STEP 10: User taps Enquiry or WhatsApp
==========================================================================

  Enquiry  -> _makePhoneCall("tel:9876543210")  -> Opens phone dialer
  WhatsApp -> _launchWhatsApp("https://wa.me/9876543210") -> Opens WhatsApp
```

---

## QUICK REFERENCE: Which Widget to Use When?

| Figma Shows | Flutter Widget | Why |
|-------------|---------------|-----|
| List of same-type cards (scrollable) | `ListView.builder` | Dynamic items, lazy loading, efficient |
| Grid of cards (2-3 columns) | `GridView.builder` | Same as ListView but multiple columns |
| Single page with mixed content | `SingleChildScrollView` + `Column` | Different sections, not repeating |
| Fixed buttons at bottom | `bottomNavigationBar` | Stays fixed, doesn't scroll |
| Pull down to refresh | `RefreshIndicator` wrapping `ListView` | Triggers API re-fetch |
| Loading skeleton | `Shimmer.fromColors` | Shows grey boxes while API loads |
| Tap to navigate | `GestureDetector` or `InkWell` | Wraps card, handles onTap |
| Image from URL | `Image.network` or `CachedNetworkImage` | Loads image from API URL |
| Image/Video slider | `MediaCarouselWidget` (our custom) | Multiple media with dots indicator |
| HTML formatted text | `HtmlWidget` (flutter_widget_from_html_core) | Renders headings, paragraphs, bold |
| Phone call button | `url_launcher` with `tel:` URI | Opens phone dialer |
| WhatsApp button | `url_launcher` with `https://wa.me/` URI | Opens WhatsApp chat |

---

## CHECKLIST: Steps to Integrate Any New Feature

- [ ] 1. Get sample JSON from backend for each endpoint
- [ ] 2. Create folder: `lib/app/{feature_name}/model/`, `controller/`, `view/`
- [ ] 3. Create LIST model (if list endpoint exists)
- [ ] 4. Create DETAIL model (if detail endpoint exists)
- [ ] 5. Create Controller with API calls + observable variables
- [ ] 6. Create List Screen with `ListView.builder` + shimmer + empty state
- [ ] 7. Create Detail Screen with `SingleChildScrollView` + shimmer
- [ ] 8. Wire up navigation from home/parent screen
- [ ] 9. Test: Loading -> Data -> Empty -> Pull to refresh -> Navigation -> Buttons
