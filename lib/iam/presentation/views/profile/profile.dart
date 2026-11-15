import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/domain/model/fuel_product_entity.dart';
import '../../../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../application/iam_store.dart';
import '../../../infrastructure/iam_api.dart';

/// Configuración de cuenta (`/profile`). [initialTab]: `organizations` abre la pestaña 3.
class Profile extends StatefulWidget {
  const Profile({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final IamStore _iamUseCases;
  bool _initialized = false;

  // Cuenta
  UserProfile? _user;
  bool _loading = true;
  String _error = '';
  List<OrganizationProfile> _organizations = [];
  String _organizationsError = '';

  // Empresa
  late bool _isBuyer;
  bool _companyLoading = true;
  String _companyError = '';
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  ProviderCompanyProfile _provider = ProviderCompanyProfile();
  List<String> _fuelTypes = [];
  final _name = TextEditingController();
  final _ruc = TextEditingController();
  final _sector = TextEditingController();
  final _address = TextEditingController();
  final _contactEmail = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();

  // Organizaciones / invitaciones
  int? _invitationOrganizationId;
  final List<OrganizationInvitation> _invitations = [];
  bool _inviting = false;
  int? _revokingId;
  OrganizationInvitation? _selectedInvitation;
  String _invitationError = '';
  String _invitationNotice = '';
  int? _revealedInvitationId;
  int? _copyingInvitationId;
  bool _onboarding = false;
  bool _onboardingRefreshing = false;
  bool _onboardingRefreshError = false;
  String _onboardingError = '';
  OrganizationProfile? _createdOrganization;
  final _onboardingName = TextEditingController();
  final _onboardingRuc = TextEditingController();
  String _onboardingType = 'CUSTOMER';
  final _invitationEmail = TextEditingController();
  String _invitationRole = MembershipRole.member;
  static const _membershipRoles = [
    MembershipRole.admin,
    MembershipRole.member,
  ]; // el backend rechaza invitar OWNER

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab == 'organizations' ? 2 : 0,
    );
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _iamUseCases = AppScope.of(context).iamStore;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _name,
      _ruc,
      _sector,
      _address,
      _contactEmail,
      _phone,
      _description,
      _onboardingName,
      _onboardingRuc,
      _invitationEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final iam = AppScope.of(context).iamStore;
    _isBuyer = iam.isBuyer;
    final userId = iam.userId;
    final companyId = _isBuyer ? iam.companyId : iam.providerId;
    _loadAccount(userId);
    if (companyId == null) {
      setState(() {
        _companyLoading = false;
        _companyError = 'profile.load-error';
      });
      return;
    }
    try {
      final company = _isBuyer
          ? await _iamUseCases.getBuyerCompany(companyId)
          : await _iamUseCases.getProviderCompany(companyId);
      if (!mounted) return;
      setState(() {
        _applyCompany(company);
        _companyLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _companyError = 'profile.load-error';
          _companyLoading = false;
        });
      }
    }
  }

  Future<void> _loadAccount(int? userId) async {
    final iam = AppScope.of(context).iamStore;
    final results = await Future.wait<Object?>([
      userId == null
          ? Future<Object?>.value(null)
          : _iamUseCases
                .getUser(userId)
                .then<Object?>((v) => v)
                .catchError((_) => null),
      iam.refreshMemberships().then<Object?>((v) => v).catchError((_) {
        _organizationsError = 'profile.load-error';
        return <OrganizationProfile>[];
      }),
    ]);
    if (!mounted) return;
    setState(() {
      _user = results[0] as UserProfile?;
      if (_user == null) _error = 'profile.load-error';
      _organizations = results[1] as List<OrganizationProfile>;
      _invitationOrganizationId = iam.organizationId;
      _loading = false;
    });
  }

  void _applyCompany(Object company) {
    if (company is BuyerCompanyProfile) {
      _name.text = company.name;
      _ruc.text = company.ruc;
      _sector.text = company.sector;
      _address.text = company.address;
      _contactEmail.text = company.contactEmail;
      _phone.text = company.phone;
    } else if (company is ProviderCompanyProfile) {
      _provider = company;
      _fuelTypes = [...company.fuelTypesOffered];
      _name.text = company.name;
      _ruc.text = company.ruc;
      _phone.text = company.phone;
      _address.text = company.address;
      _description.text = company.description;
    }
  }

  // --- Validaciones del formulario de empresa ---
  String? _required(String? v) =>
      (v ?? '').isEmpty ? context.tr('validation.required') : null;

  String? _rucValidator(String? v) {
    if ((v ?? '').isEmpty) return context.tr('validation.required');
    if (!RegExp(r'^[0-9]{11}$').hasMatch(v!)) {
      return context.tr('profile.ruc-invalid');
    }
    return null;
  }

  String? _emailValidator(String? v) {
    if ((v ?? '').isEmpty) return context.tr('validation.required');
    if (!RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(v!)) {
      return context.tr('validation.email');
    }
    return null;
  }

  bool get _companyValid =>
      _required(_name.text) == null &&
      _rucValidator(_ruc.text) == null &&
      _required(_address.text) == null &&
      _required(_phone.text) == null &&
      (!_isBuyer ||
          (_required(_sector.text) == null &&
              _emailValidator(_contactEmail.text) == null));

  bool get _canSave =>
      !_companyLoading &&
      _companyError.isEmpty &&
      _dirty &&
      _companyValid &&
      (_isBuyer || _fuelTypes.isNotEmpty) &&
      !_saving;

  void _markDirty() => setState(() {
    _dirty = true;
    _saved = false;
  });

  void _toggleFuelType(String type) {
    setState(() {
      _fuelTypes = _fuelTypes.contains(type)
          ? _fuelTypes.where((v) => v != type).toList()
          : [..._fuelTypes, type];
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final iam = AppScope.of(context).iamStore;
    final id = _isBuyer ? iam.companyId : iam.providerId;
    if (id == null || !_canSave) return;
    setState(() {
      _error = '';
      _saved = false;
      _saving = true;
    });
    try {
      final Object company;
      if (_isBuyer) {
        company = await _iamUseCases.updateBuyerCompany(
          id,
          BuyerCompanyProfile(
            id: id,
            name: _name.text,
            ruc: _ruc.text,
            sector: _sector.text,
            address: _address.text,
            contactEmail: _contactEmail.text,
            phone: _phone.text,
          ),
        );
      } else {
        company = await _iamUseCases.updateProviderCompany(
          id,
          ProviderCompanyProfile(
            id: id,
            name: _name.text,
            ruc: _ruc.text,
            rating: _provider.rating,
            address: _address.text,
            phone: _phone.text,
            fuelTypesOffered: _fuelTypes,
            description: _description.text,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _applyCompany(company);
        _dirty = false;
        _saved = true;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'profile.save-error';
          _saving = false;
        });
      }
    }
  }

  // --- Organizaciones ---
  OrganizationProfile? get _invitationOrganization => _organizations
      .where((o) => o.id == _invitationOrganizationId)
      .firstOrNull;

  List<OrganizationInvitation> get _visibleInvitations => _invitations
      .where((i) => i.organizationId == _invitationOrganizationId)
      .toList();

  bool get _invitationBusy =>
      _inviting || _revokingId != null || _selectedInvitation != null;

  void _selectInvitationOrganization(int? id) {
    if (id == null || _invitationBusy) return;
    if (!AppScope.of(context).iamStore.selectOrganization(id)) return;
    setState(() {
      _invitationOrganizationId = id;
      _invitationError = '';
      _invitationNotice = '';
    });
  }

  bool get _onboardingLocked =>
      _onboarding || _onboardingRefreshing || _onboardingRefreshError;

  Future<void> _createOrganization() async {
    final name = _onboardingName.text.trim();
    final ruc = _onboardingRuc.text.trim();
    if (name.isEmpty ||
        name.length > 150 ||
        ruc.isEmpty ||
        ruc.length > 11 ||
        _onboardingLocked) {
      return;
    }
    setState(() {
      _onboardingError = '';
      _createdOrganization = null;
      _onboarding = true;
    });
    try {
      final organization = await _iamUseCases.onboardOrganization(
        name,
        ruc,
        _onboardingType,
      );
      if (!mounted) return;
      setState(() {
        _createdOrganization = organization;
        _onboarding = false;
        _onboardingName.clear();
        _onboardingRuc.clear();
        _onboardingType = 'CUSTOMER';
      });
      _refreshCreatedOrganizations();
    } catch (e) {
      if (!mounted) return;
      final key = e is ApiException ? e.message : 'errors.generic';
      setState(() {
        _onboardingError =
            const [
              '400',
              '401',
              '403',
              '409',
            ].any((s) => key == 'errors.http-$s')
            ? key.replaceFirst('errors.', 'onboarding.')
            : key;
        _onboarding = false;
      });
    }
  }

  Future<void> _refreshCreatedOrganizations() async {
    if (_createdOrganization == null || _onboardingRefreshing) return;
    final iam = AppScope.of(context).iamStore;
    setState(() {
      _onboardingRefreshing = true;
      _onboardingRefreshError = false;
    });
    try {
      final organizations = await iam.refreshMemberships();
      if (!mounted) return;
      setState(() {
        _organizations = organizations;
        _organizationsError = '';
        _invitationOrganizationId = iam.organizationId;
        _onboardingRefreshing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _onboardingRefreshError = true;
          _onboardingRefreshing = false;
        });
      }
    }
  }

  Future<void> _inviteMember() async {
    final organizationId = _invitationOrganizationId;
    final email = _invitationEmail.text.trim();
    if (organizationId == null ||
        _invitationOrganization == null ||
        _inviting ||
        _revokingId != null) {
      return;
    }
    if (email.isEmpty ||
        email.length > 150 ||
        !RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(email)) {
      return;
    }
    setState(() {
      _invitationError = '';
      _invitationNotice = '';
      _inviting = true;
    });
    try {
      final invitation = await _iamUseCases.inviteMember(
        organizationId,
        email,
        _invitationRole,
      );
      if (!mounted) return;
      setState(() {
        _invitations.add(invitation);
        _invitationEmail.clear();
        _invitationRole = MembershipRole.member;
        _invitationNotice = 'invitations.created';
        _inviting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _invitationError = e is ApiException ? e.message : 'errors.generic';
          _inviting = false;
        });
      }
    }
  }

  Future<void> _copyInvitation(OrganizationInvitation invitation) async {
    if (_copyingInvitationId != null ||
        invitation.status != 'PENDING' ||
        invitation.token.isEmpty) {
      return;
    }
    setState(() {
      _invitationError = '';
      _invitationNotice = '';
      _copyingInvitationId = invitation.id;
    });
    try {
      await Clipboard.setData(ClipboardData(text: invitation.token));
      if (mounted) {
        setState(() => _invitationNotice = 'invitations.link-copied');
      }
    } catch (_) {
      if (mounted) setState(() => _invitationError = 'invitations.copy-failed');
    } finally {
      if (mounted) setState(() => _copyingInvitationId = null);
    }
  }

  Future<void> _requestRevoke(OrganizationInvitation invitation) async {
    if (invitation.status != 'PENDING' || _invitationBusy) return;
    setState(() {
      _invitationError = '';
      _invitationNotice = '';
      _selectedInvitation = invitation;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('invitations.revoke-title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              invitation.email,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(_invitationOrganization?.name ?? ''),
            Text(context.tr('invitations.revoke-confirmation')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('confirm.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('invitations.revoke')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _selectedInvitation = null);
    if (confirmed != true) return;
    setState(() => _revokingId = invitation.id);
    try {
      final revoked = await _iamUseCases.revokeInvitation(invitation.id);
      if (!mounted) return;
      setState(() {
        final index = _invitations.indexWhere((i) => i.id == revoked.id);
        if (index >= 0) {
          _invitations[index] = revoked.copyWith(
            token: _invitations[index].token,
          );
        }
        _revealedInvitationId = null;
        _invitationNotice = 'invitations.revoked';
        _revokingId = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _invitationError = e is ApiException ? e.message : 'errors.generic';
          _revokingId = null;
        });
      }
    }
  }

  String _role(String value) => value.replaceFirst(RegExp(r'^ROLE_'), '');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            spacing: 16,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('profile.title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_user != null)
                      Text(
                        _user!.username,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Semantics(
              label: context.tr('profile.loading'),
              child: const CircularProgressIndicator(),
            ),
          )
        else ...[
          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabs,
              labelColor: FgColors.primary,
              tabs: [
                Tab(text: context.tr('profile.tab-account')),
                Tab(text: context.tr('profile.tab-company')),
                Tab(text: context.tr('profile.tab-organizations')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _accountTab(context),
                _companyTab(context),
                _organizationsTab(context),
              ],
            ),
          ),
          if (_user != null && _tabs.index == 1) _footer(context),
        ],
      ],
    );
  }

  Widget _accountTab(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.tr(_error),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(user.username),
                subtitle: Text(context.tr('profile.username')),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [for (final r in user.roles) _chip(_role(r))],
                  ),
                ),
                subtitle: Text(context.tr('profile.roles')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _companyField(
    TextEditingController c,
    String labelKey, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int? maxLength,
    int maxLines = 1,
  }) => TextFormField(
    controller: c,
    keyboardType: keyboard,
    maxLength: maxLength,
    maxLines: maxLines,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: validator,
    onChanged: (_) => _markDirty(),
    decoration: InputDecoration(
      labelText: context.tr(labelKey),
      counterText: '',
    ),
  );

  Widget _companyTab(BuildContext context) {
    if (_companyLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(context.tr('profile.loading')),
      );
    }
    if (_companyError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.tr(_companyError),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _companyField(_name, 'auth.company', validator: _required),
              _companyField(
                _ruc,
                'auth.ruc',
                validator: _rucValidator,
                keyboard: TextInputType.number,
                maxLength: 11,
              ),
              if (_isBuyer) ...[
                _companyField(_sector, 'auth.sector', validator: _required),
                _companyField(_address, 'auth.address', validator: _required),
                _companyField(
                  _contactEmail,
                  'profile.contact-email',
                  validator: _emailValidator,
                  keyboard: TextInputType.emailAddress,
                ),
                _companyField(
                  _phone,
                  'auth.phone',
                  validator: _required,
                  keyboard: TextInputType.phone,
                ),
              ] else ...[
                _companyField(
                  _phone,
                  'auth.phone',
                  validator: _required,
                  keyboard: TextInputType.phone,
                ),
                _companyField(_address, 'auth.address', validator: _required),
                Text(context.tr('auth.fuel-types')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in fuelTypes)
                      FilterChip(
                        label: Text(
                          context.tr('fuel-type.${type.toLowerCase()}'),
                        ),
                        selected: _fuelTypes.contains(type),
                        onSelected: (_) => _toggleFuelType(type),
                      ),
                  ],
                ),
                if (_fuelTypes.isEmpty)
                  Text(
                    context.tr('auth.fuel-types-required'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                TextFormField(
                  initialValue: _provider.rating?.toString() ?? '—',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.rating'),
                    helperText: context.tr('profile.rating-readonly'),
                  ),
                ),
                _companyField(_description, 'auth.description', maxLines: 3),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (_error.isNotEmpty && _user != null)
            Text(
              context.tr(_error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_saved)
            Text(
              context.tr('profile.saved'),
              style: const TextStyle(color: FgColors.success),
            ),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(
              context.tr(_saving ? 'profile.saving' : 'profile.save'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _organizationsTab(BuildContext context) {
    final locked = _onboardingLocked;
    final onboardingReady =
        _onboardingName.text.trim().isNotEmpty &&
        _onboardingRuc.text.trim().isNotEmpty &&
        !locked;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              context.tr('onboarding.title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              context.tr('onboarding.help'),
              style: const TextStyle(color: FgColors.textMuted),
            ),
            TextField(
              controller: _onboardingName,
              enabled: !locked,
              maxLength: 150,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('onboarding.name'),
                counterText: '',
              ),
            ),
            TextField(
              controller: _onboardingRuc,
              enabled: !locked,
              maxLength: 11,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('onboarding.ruc'),
                counterText: '',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _onboardingType,
              decoration: InputDecoration(
                labelText: context.tr('onboarding.type'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'CUSTOMER',
                  child: Text(context.tr('onboarding.type-customer')),
                ),
                DropdownMenuItem(
                  value: 'DISTRIBUTOR',
                  child: Text(context.tr('onboarding.type-distributor')),
                ),
              ],
              onChanged: locked
                  ? null
                  : (v) => setState(() => _onboardingType = v ?? 'CUSTOMER'),
            ),
            FilledButton(
              onPressed: onboardingReady ? _createOrganization : null,
              child: Text(
                context.tr(
                  _onboarding ? 'onboarding.creating' : 'onboarding.create',
                ),
              ),
            ),
            if (_createdOrganization != null)
              Text(
                '${context.tr('onboarding.created')} · ${_createdOrganization!.name}',
                style: const TextStyle(color: FgColors.success),
              ),
            if (_onboardingError.isNotEmpty)
              Text(
                context.tr(_onboardingError),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_onboardingRefreshError) ...[
              Text(
                context.tr('onboarding.refresh-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              OutlinedButton(
                onPressed: _onboardingRefreshing
                    ? null
                    : _refreshCreatedOrganizations,
                child: Text(context.tr('onboarding.retry-refresh')),
              ),
            ],
            const Divider(),
            if (_organizationsError.isNotEmpty)
              Text(
                context.tr(_organizationsError),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_organizations.isNotEmpty) ...[
              for (final org in _organizations)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.apartment)),
                    title: Text(
                      org.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _chip(
                            context.tr(
                              org.type == 'CUSTOMER'
                                  ? 'onboarding.type-customer'
                                  : 'onboarding.type-distributor',
                            ),
                          ),
                          _chip(
                            context.tr(
                              'invitations.role-${org.role.toLowerCase()}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ..._invitationsSection(context),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.apartment,
                      size: 40,
                      color: FgColors.textMuted,
                    ),
                    Text(context.tr('profile.no-organizations')),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _invitationsSection(BuildContext context) {
    final emailText = _invitationEmail.text.trim();
    final emailValid =
        emailText.isNotEmpty &&
        emailText.length <= 150 &&
        RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(emailText);
    final busy = _inviting || _revokingId != null;
    const help = TextStyle(color: FgColors.textMuted, fontSize: 13);
    return [
      const Divider(),
      Text(
        context.tr('invitations.title'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (_organizations.length > 1) ...[
        DropdownButtonFormField<int>(
          key: ValueKey(_invitationOrganizationId),
          initialValue: _invitationOrganizationId,
          decoration: InputDecoration(
            labelText: context.tr('onboarding.context'),
          ),
          items: [
            for (final o in _organizations)
              DropdownMenuItem(value: o.id, child: Text(o.name)),
          ],
          onChanged: _invitationBusy ? null : _selectInvitationOrganization,
        ),
        Text(context.tr('onboarding.context-hint'), style: help),
      ] else ...[
        Text(
          '${context.tr('onboarding.context')}: ${_invitationOrganization?.name ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(context.tr('onboarding.context-hint'), style: help),
      ],
      Text(context.tr('invitations.no-email'), style: help),
      TextField(
        controller: _invitationEmail,
        enabled: !busy,
        keyboardType: TextInputType.emailAddress,
        maxLength: 150,
        onChanged: (_) => setState(() {
          _invitationError = '';
          _invitationNotice = '';
        }),
        decoration: InputDecoration(
          labelText: context.tr('invitations.email'),
          counterText: '',
          errorText: emailText.isNotEmpty && !emailValid
              ? context.tr('validation.email')
              : null,
        ),
      ),
      DropdownButtonFormField<String>(
        key: ValueKey(_invitationRole),
        initialValue: _invitationRole,
        decoration: InputDecoration(labelText: context.tr('invitations.role')),
        items: [
          for (final r in _membershipRoles)
            DropdownMenuItem(
              value: r,
              child: Text(context.tr('invitations.role-${r.toLowerCase()}')),
            ),
        ],
        onChanged: busy
            ? null
            : (v) =>
                  setState(() => _invitationRole = v ?? MembershipRole.member),
      ),
      FilledButton(
        onPressed: emailValid && !busy ? _inviteMember : null,
        child: Text(
          context.tr(_inviting ? 'invitations.creating' : 'invitations.create'),
        ),
      ),
      if (_invitationError.isNotEmpty)
        Text(
          context.tr(_invitationError),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (_invitationNotice.isNotEmpty)
        Text(
          context.tr(_invitationNotice),
          style: const TextStyle(color: FgColors.success),
        ),
      Text(
        context.tr('invitations.session-title'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Text(context.tr('invitations.session-hint'), style: help),
      if (_visibleInvitations.isEmpty)
        Text(context.tr('invitations.empty'), style: help)
      else
        for (final inv in _visibleInvitations) _invitationCard(context, inv),
    ];
  }

  Widget _invitationCard(BuildContext context, OrganizationInvitation inv) {
    final revealed = _revealedInvitationId == inv.id;
    final pending = inv.status == 'PENDING';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              inv.email,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(context.tr('invitations.role-${inv.role.toLowerCase()}')),
                StatusChip(
                  label: context.tr(
                    'invitations.status-${inv.status.toLowerCase()}',
                  ),
                  status: inv.status,
                ),
                Text(
                  '${context.tr('invitations.expires')}: ${formatDateTime(inv.expiresAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (pending && inv.token.isNotEmpty) ...[
              Text(
                context.tr('invitations.token'),
                style: const TextStyle(fontSize: 12, color: FgColors.textMuted),
              ),
              SelectableText(
                revealed ? inv.token : '••••••••••••',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _revealedInvitationId = revealed ? null : inv.id,
                    ),
                    child: Text(
                      context.tr(
                        revealed
                            ? 'invitations.hide-token'
                            : 'invitations.show-token',
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _copyingInvitationId != null
                        ? null
                        : () => _copyInvitation(inv),
                    child: Text(context.tr('invitations.copy-link')),
                  ),
                ],
              ),
            ],
            if (pending)
              OutlinedButton(
                onPressed:
                    _inviting ||
                        _revokingId != null ||
                        _selectedInvitation != null
                    ? null
                    : () => _requestRevoke(inv),
                child: Text(
                  context.tr(
                    _revokingId == inv.id
                        ? 'invitations.revoking'
                        : 'invitations.revoke',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
