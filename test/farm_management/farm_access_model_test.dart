import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';

/// What the app is allowed to OFFER.
///
/// The server is the real gate — every farm route sits behind
/// `farm.access:<ability>` — so these flags decide which buttons are drawn, not
/// what is permitted. Getting them wrong turns a partner's missing permission
/// into "Failed to update farm" instead of a control that was never there.
void main() {
  group('AccessPermissions.fromJson', () {
    test('reads the block the farm list sends', () {
      final p = AccessPermissions.fromJson(const {
        'view': true,
        'edit': false,
        'tank_status': true,
        'total_feed': false,
        'create': true,
        'delete': false,
      });

      expect(p.view, isTrue);
      expect(p.edit, isFalse);
      expect(p.tankStatus, isTrue);
      expect(p.totalFeed, isFalse);
      expect(p.create, isTrue);
      expect(p.delete, isFalse);
    });

    test('denies everything when the block is missing', () {
      final p = AccessPermissions.fromJson(null);

      expect(p.view, isFalse);
      expect(p.edit, isFalse);
      expect(p.tankStatus, isFalse);
      expect(p.totalFeed, isFalse);
      expect(p.create, isFalse);
      expect(p.delete, isFalse);
    });

    test('only a real true counts — 1, "true" and null are not', () {
      // Fails closed: anything that is not a JSON boolean true is a denial.
      final p = AccessPermissions.fromJson(const {
        'view': 1,
        'edit': 'true',
        'create': null,
      });

      expect(p.view, isFalse);
      expect(p.edit, isFalse);
      expect(p.create, isFalse);
    });
  });

  group('FarmAccess.fromJson', () {
    test('an owner may do everything', () {
      final a = FarmAccess.fromJson(const {
        'role': 'owner',
        'is_owner': true,
        'permissions': {
          'view': true,
          'edit': true,
          'tank_status': true,
          'total_feed': true,
          'create': true,
          'delete': true,
        },
      });

      expect(a.isOwner, isTrue);
      expect(a.canView, isTrue);
      expect(a.canEdit, isTrue);
      expect(a.canChangeTankStatus, isTrue);
      expect(a.canEditTotalFeed, isTrue);
      expect(a.canCreate, isTrue);
      expect(a.canDelete, isTrue);
    });

    test('a view-only manager gets exactly one ability', () {
      final a = FarmAccess.fromJson(const {
        'role': 'manager',
        'is_owner': false,
        'permissions': {
          'view': true,
          'edit': false,
          'tank_status': false,
          'total_feed': false,
          'create': false,
          'delete': false,
        },
      });

      expect(a.role, 'manager');
      expect(a.isOwner, isFalse);
      expect(a.canView, isTrue);
      expect(a.canEdit, isFalse);
      expect(a.canChangeTankStatus, isFalse);
      expect(a.canEditTotalFeed, isFalse);
      expect(a.canCreate, isFalse);
      expect(a.canDelete, isFalse);
    });

    test('a partner holding one extra ability holds only that one', () {
      // Mirrors a real grant: view plus the tank toggle, nothing else.
      final a = FarmAccess.fromJson(const {
        'role': 'partner',
        'is_owner': false,
        'permissions': {'view': true, 'tank_status': true},
      });

      expect(a.canView, isTrue);
      expect(a.canChangeTankStatus, isTrue);
      expect(a.canEdit, isFalse);
      expect(a.canEditTotalFeed, isFalse);
      expect(a.canDelete, isFalse);
    });

    test('ownership overrides the flags, however they arrive', () {
      // is_owner true with an empty permission block still means everything:
      // the server treats the farm's owner as unconditional.
      final a = FarmAccess.fromJson(<String, dynamic>{
        'role': 'owner',
        'is_owner': true,
        'permissions': <String, dynamic>{},
      });

      expect(a.canEdit, isTrue);
      expect(a.canDelete, isTrue);
      expect(a.canEditTotalFeed, isTrue);
    });

    test('a payload with no access block falls back to full rights', () {
      // Deliberate: the server is the gate, and hiding every control on an old
      // response would leave an owner unable to work.
      final a = FarmAccess.fromJson(null);

      expect(a.isOwner, isTrue);
      expect(a.canEdit, isTrue);
      expect(a.canDelete, isTrue);
    });
  });

  group('canShareAccess', () {
    test('anyone holding any ability may pass it on', () {
      final viewOnly = FarmAccess.fromJson(const {
        'role': 'manager',
        'is_owner': false,
        'permissions': {'view': true},
      });

      expect(viewOnly.canShareAccess, isTrue);
    });

    test('someone holding nothing may not', () {
      final none = FarmAccess.fromJson(<String, dynamic>{
        'role': 'none',
        'is_owner': false,
        'permissions': <String, dynamic>{},
      });

      expect(none.canShareAccess, isFalse);
    });
  });

  group('FarmMember.fromJson', () {
    test('reads a member row', () {
      final m = FarmMember.fromJson(const {
        'id': 7,
        'farmer_id': 138,
        'name': 'Ravi Kumar',
        'mobile': '9000000001',
        'role': 'partner',
        'status': 'active',
        'granted_by': 'Saiprakash',
        'permissions': {'view': true, 'edit': true},
      });

      expect(m.id, 7);
      expect(m.farmerId, 138);
      expect(m.name, 'Ravi Kumar');
      expect(m.isPartner, isTrue);
      expect(m.isActive, isTrue);
      expect(m.permissions.edit, isTrue);
    });

    test('falls back to the mobile when nobody has a name on file', () {
      // Someone added by phone number has not signed up yet, so an empty card
      // would be all the owner saw.
      final m = FarmMember.fromJson(const {
        'id': 8,
        'name': '   ',
        'mobile': '9000000002',
        'role': 'manager',
      });

      expect(m.name, '9000000002');
      expect(m.isPartner, isFalse);
      expect(m.isActive, isTrue, reason: 'status defaults to active');
    });

    test('a revoked member is not active', () {
      final m = FarmMember.fromJson(const {
        'id': 9,
        'name': 'Old Manager',
        'role': 'manager',
        'status': 'revoked',
      });

      expect(m.isActive, isFalse);
    });
  });

  group('FarmRole', () {
    test('carries the value the API expects', () {
      expect(FarmRole.manager.apiValue, 'manager');
      expect(FarmRole.partner.apiValue, 'partner');
    });

    test('labels the screens singular and plural', () {
      expect(FarmRole.manager.label, 'Manager');
      expect(FarmRole.manager.pluralLabel, 'Managers');
      expect(FarmRole.partner.label, 'Partner');
      expect(FarmRole.partner.pluralLabel, 'Partners');
    });

    test('matches a member row back to a role, defaulting to manager', () {
      expect(FarmRole.fromApi('partner'), FarmRole.partner);
      expect(FarmRole.fromApi('PARTNER'), FarmRole.partner);
      expect(FarmRole.fromApi('manager'), FarmRole.manager);
      expect(FarmRole.fromApi(null), FarmRole.manager);
      expect(FarmRole.fromApi('something else'), FarmRole.manager);
    });
  });
}
