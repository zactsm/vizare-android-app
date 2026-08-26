-- ============================================================
-- Vizare Real Estate Database Seed File
-- Comprehensive Fixtures, 20 Verified 3D House Models & Media
-- ============================================================

-- 1. Seed Auth Users (if running in local Supabase environment)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'auth' and table_name = 'users') then
    insert into auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      aud,
      role
    )
    values
      (
        '11111111-1111-1111-1111-111111111111'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'admin@vizare.com',
        crypt('AdminPassword123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Vizare Administrator","role":"admin","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '22222222-2222-2222-2222-222222222222'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'sarah.jenkins@luxuryhomes.com',
        crypt('HomeownerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Sarah Jenkins","role":"homeowner","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '33333333-3333-3333-3333-333333333333'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'alexander.vance@vancerealty.com',
        crypt('HomeownerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Alexander Vance","role":"homeowner","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '44444444-4444-4444-4444-444444444444'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'elena.rostova@azureestates.com',
        crypt('HomeownerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Elena Rostova","role":"homeowner","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '77777777-7777-7777-7777-777777777777'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'marcus.thorne@archilux.com',
        crypt('HomeownerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Marcus Thorne","role":"homeowner","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '88888888-8888-8888-8888-888888888888'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'isabella.cruz@pacificcoastal.com',
        crypt('HomeownerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Isabella Cruz","role":"homeowner","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '55555555-5555-5555-5555-555555555555'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'david.chen@buyer.com',
        crypt('BuyerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"David Chen","role":"homebuyer","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '66666666-6666-6666-6666-666666666666'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'olivia.taylor@buyer.com',
        crypt('BuyerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Olivia Taylor","role":"homebuyer","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      ),
      (
        '99999999-9999-9999-9999-999999999999'::uuid,
        '00000000-0000-0000-0000-000000000000'::uuid,
        'james.wilson@buyer.com',
        crypt('BuyerPass123!', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"James Wilson","role":"homebuyer","has_password":true}'::jsonb,
        now(),
        now(),
        'authenticated',
        'authenticated'
      )
    on conflict (id) do update set
      email = excluded.email,
      raw_user_meta_data = excluded.raw_user_meta_data,
      updated_at = now();
  end if;
exception
  when others then
    null;
end $$;

-- 2. Seed Public Profiles
insert into public.profiles (
  auth_user_id,
  email,
  full_name,
  phone,
  role,
  profile_pic,
  has_password,
  is_active
)
values
  (
    '11111111-1111-1111-1111-111111111111'::uuid,
    'admin@vizare.com',
    'Vizare Administrator',
    '+1 (555) 019-2831',
    'admin'::public.user_role,
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '22222222-2222-2222-2222-222222222222'::uuid,
    'sarah.jenkins@luxuryhomes.com',
    'Sarah Jenkins',
    '+1 (555) 342-8819',
    'homeowner'::public.user_role,
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'alexander.vance@vancerealty.com',
    'Alexander Vance',
    '+1 (555) 789-2244',
    'homeowner'::public.user_role,
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '44444444-4444-4444-4444-444444444444'::uuid,
    'elena.rostova@azureestates.com',
    'Elena Rostova',
    '+1 (555) 612-4490',
    'homeowner'::public.user_role,
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '77777777-7777-7777-7777-777777777777'::uuid,
    'marcus.thorne@archilux.com',
    'Marcus Thorne',
    '+1 (555) 482-9901',
    'homeowner'::public.user_role,
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '88888888-8888-8888-8888-888888888888'::uuid,
    'isabella.cruz@pacificcoastal.com',
    'Isabella Cruz',
    '+1 (555) 831-2290',
    'homeowner'::public.user_role,
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555555'::uuid,
    'david.chen@buyer.com',
    'David Chen',
    '+1 (555) 901-3321',
    'homebuyer'::public.user_role,
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666666'::uuid,
    'olivia.taylor@buyer.com',
    'Olivia Taylor',
    '+1 (555) 433-1188',
    'homebuyer'::public.user_role,
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    true,
    true
  ),
  (
    '99999999-9999-9999-9999-999999999999'::uuid,
    'james.wilson@buyer.com',
    'James Wilson',
    '+1 (555) 720-4109',
    'homebuyer'::public.user_role,
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
    true,
    true
  )
on conflict (email) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role,
  profile_pic = excluded.profile_pic,
  has_password = excluded.has_password,
  is_active = excluded.is_active,
  updated_at = now();

-- 3. Seed Notification Preferences
insert into public.notification_preferences (
  profile_id,
  push_notifications,
  email_notifications,
  in_app_notifications
)
select
  p.id,
  true,
  true,
  true
from public.profiles p
on conflict (profile_id) do update set
  push_notifications = excluded.push_notifications,
  email_notifications = excluded.email_notifications,
  in_app_notifications = excluded.in_app_notifications,
  updated_at = now();

-- 4. Seed 20 Realistic Properties with 20 Unique 3D House Models
do $$
declare
  v_sarah_id bigint;
  v_vance_id bigint;
  v_elena_id bigint;
  v_marcus_id bigint;
  v_isabella_id bigint;
  v_chen_id bigint;
  v_taylor_id bigint;
  v_wilson_id bigint;
  
  v_prop_1 bigint;
  v_prop_2 bigint;
  v_prop_3 bigint;
  v_prop_4 bigint;
  v_prop_5 bigint;
  v_prop_6 bigint;
  v_prop_7 bigint;
  v_prop_8 bigint;
  v_prop_9 bigint;
  v_prop_10 bigint;
  v_prop_11 bigint;
  v_prop_12 bigint;
  v_prop_13 bigint;
  v_prop_14 bigint;
  v_prop_15 bigint;
  v_prop_16 bigint;
  v_prop_17 bigint;
  v_prop_18 bigint;
  v_prop_19 bigint;
  v_prop_20 bigint;
begin
  select id into v_sarah_id from public.profiles where email = 'sarah.jenkins@luxuryhomes.com';
  select id into v_vance_id from public.profiles where email = 'alexander.vance@vancerealty.com';
  select id into v_elena_id from public.profiles where email = 'elena.rostova@azureestates.com';
  select id into v_marcus_id from public.profiles where email = 'marcus.thorne@archilux.com';
  select id into v_isabella_id from public.profiles where email = 'isabella.cruz@pacificcoastal.com';
  select id into v_chen_id from public.profiles where email = 'david.chen@buyer.com';
  select id into v_taylor_id from public.profiles where email = 'olivia.taylor@buyer.com';
  select id into v_wilson_id from public.profiles where email = 'james.wilson@buyer.com';

  -- Property 1: The Glass Horizon Villa (Beverly Hills, CA)
  -- 3D House Asset: Littlest Tokyo (Multi-Story Japanese Townhouse Architectural Diorama)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'The Glass Horizon Villa',
    'Beverly Hills, CA 90210',
    '$4,850,000',
    'An architectural masterpiece perched in the hills, featuring panoramic floor-to-ceiling glass walls, an infinity edge pool, open-concept living pavilion, and custom Italian designer finishes. Includes interactive 3D model view.',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/LittlestTokyo.glb',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_1;

  -- Property 2: Neo Tokyo Skyline Penthouse (Shibuya, Tokyo, Japan)
  -- 3D House Asset: Residential Family House (Sketchfab: b36b822986f44ca99e6cfec20386a955)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_vance_id,
    'Neo Tokyo Skyline Penthouse',
    'Shibuya, Tokyo, Japan',
    '$3,200,000',
    'Spectacular multi-level urban penthouse overlooking the neon skyline. Features automated smart home climate systems, private sky deck, bespoke woodwork, and fully furnished spatial layout.',
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/residential-family-house-b36b822986f44ca99e6cfec20386a955',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_2;

  -- Property 3: Nordic Minimalist Residence (Aspen, CO)
  -- 3D House Asset: Modern Forest Wooden House Villa Retreat
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'Nordic Minimalist Residence',
    'Aspen, CO 81611',
    '$2,450,000',
    'Modern Scandinavian architectural retreat crafted with sustainable Douglas fir beams, polished concrete radiant floors, and floor-to-ceiling forest views. Includes bespoke timber exterior model.',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/AVIFTest/forest_house.glb',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_3;

  -- Property 4: Villa Serena Waterfront Estate (Miami Beach, FL)
  -- 3D House Asset: Low Poly House 1 (Sketchfab: 72b37584f1a74e66914d4c57ea7f70d8)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_elena_id,
    'Villa Serena Waterfront Estate',
    'Miami Beach, FL 33139',
    '$6,900,000',
    'Prime waterfront estate with private deep-water yacht dock, expansive outdoor entertaining terrace, resort-style heated pool, and lush tropical landscape architecture.',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-1-72b37584f1a74e66914d4c57ea7f70d8',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_4;

  -- Property 5: The Modernist Cantilever House (Austin, TX)
  -- 3D House Asset: Low Poly House 5 (Sketchfab: d39346d08e494adfb4d1c70db350f2ce)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_vance_id,
    'The Modernist Cantilever House',
    'Austin, TX 78746',
    '$1,875,000',
    'Dramatic steel and cedar cantilever residence nestled into the hillside. Boasts energy-positive solar arrays, smart automated illumination, and custom industrial fixture fittings.',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-5-d39346d08e494adfb4d1c70db350f2ce',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_5;

  -- Property 6: The Obsidian Contemporary Penthouse (Tribeca, New York, NY)
  -- 3D House Asset: Low Poly House 4 (Sketchfab: 7b9d7d2a530648fe8ab096c9fba23be9)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'The Obsidian Contemporary Penthouse',
    'Tribeca, New York, NY 10013',
    '$5,400,000',
    'High-floor Tribeca loft penthouse with 14-foot ceilings, direct key-elevator access, private wrap-around terrace, custom marble fireplace lounge, and breathtaking river vistas.',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-4-7b9d7d2a530648fe8ab096c9fba23be9',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_6;

  -- Property 7: Heritage Craftsman Stone Villa & Studio (Pasadena, CA)
  -- 3D House Asset: Stone Masonry Mountain Cottage & Bungalow
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_elena_id,
    'Heritage Craftsman Villa & Studio',
    'Pasadena, CA 91105',
    '$1,650,000',
    'Elegantly restored 1920s Craftsman residence featuring handcrafted mahogany joinery, original river rock fireplace, stone masonry accents, and detached guest carriage house.',
    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/cottage/cottage.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_7;

  -- Property 8: Celestial Horizon Gallery Loft (Seattle, WA)
  -- 3D House Asset: Low Poly House 3 (Sketchfab: d7d42b52319d44cf89d6d6404970cd46)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_vance_id,
    'Celestial Horizon Gallery Loft',
    'Seattle, WA 98101',
    '$1,290,000',
    'Top-floor modern gallery loft in downtown Seattle featuring exposed industrial trusses, polished epoxy floors, museum lighting grid, and avant-garde architectural sculptures.',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-3-d7d42b52319d44cf89d6d6404970cd46',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_8;

  -- Property 9: Sunset Ridge Modern Estate (Scottsdale, AZ)
  -- 3D House Asset: Modern Minimalist House Scene & Architecture
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'Sunset Ridge Modern Estate',
    'Scottsdale, AZ 85255',
    '$2,950,000',
    'Newly constructed desert modern estate featuring rammed-earth accent walls, zero-edge reflection pool, indoor-outdoor glass pocket doors, and iridescent ambient illumination.',
    'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/house_scene.glb',
    false,
    'pending'::public.property_status
  )
  returning id into v_prop_9;

  -- Property 10: Pinecrest Alpine Sanctuary (Lake Tahoe, NV)
  -- 3D House Asset: Multi-Story Timber Alpine Chalet & Inn
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_elena_id,
    'Pinecrest Alpine Sanctuary',
    'Lake Tahoe, NV 89449',
    '$3,750,000',
    'Custom timber and stone alpine retreat with private ski trail access, heated driveway, wellness sauna pavilion, and state-of-the-art acoustic listening lounge.',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/inn/inn.glb',
    false,
    'draft'::public.property_status
  )
  returning id into v_prop_10;

  -- Property 11: Cyberpunk Metropolis Tower Suite (San Francisco, CA)
  -- 3D House Asset: Metropolitan Skyline City Towers Complex (VirtualCity)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_vance_id,
    'Cyberpunk Artefact Penthouse Gallery',
    'San Francisco, CA 94105',
    '$4,100,000',
    'Exclusive SoMa tech penthouse with high-security biometric entry, private roof garden, and panoramic city views across the futuristic downtown skyline.',
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/VirtualCity/glTF-Binary/VirtualCity.glb',
    false,
    'sold'::public.property_status
  )
  returning id into v_prop_11;

  -- Property 12: Rolling Hills Farmstead & Mill Lodge (Nashville, TN)
  -- 3D House Asset: Rustic Timber Millhouse & Estate Lodge (SawMill)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'Rolling Hills Farmstead & Manor',
    'Nashville, TN 37215',
    '$1,450,000',
    'Pastoral country estate with 10 rolling acres, equestrian stables, heritage millhouse lodge architecture, and natural creek frontage.',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/villagePack/sawMill/sawMill.glb',
    false,
    'rejected'::public.property_status
  )
  returning id into v_prop_12;

  -- Property 13: Azure Coastline Mediterranean Villa (Malibu, CA)
  -- 3D House Asset: Low Poly House 2 (Sketchfab: 470dd32acf1847c29acaf0fc898e414b)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_marcus_id,
    'Azure Coastline Mediterranean Villa',
    'Malibu, CA 90265',
    '$8,250,000',
    'Gated oceanfront compound with dual Mediterranean guest villas, private bluff staircase to beach, infinity jacuzzi, and expansive terracotta loggias overlooking the Pacific.',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-2-470dd32acf1847c29acaf0fc898e414b',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_13;

  -- Property 14: Emerald Valley Alpine Resort Estate (Vail, CO)
  -- 3D House Asset: Low Poly House 3 (Sketchfab: d2722c2e056a48ca8c922298b7a9e88b)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_isabella_id,
    'Emerald Valley Alpine Resort Estate',
    'Vail, CO 81657',
    '$5,600,000',
    'Expansive alpine valley estate surrounded by pristine aspen groves. Includes main chalet, secondary guest lodge, private trout stream, and heated outdoor stone terrace.',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-house-3-d2722c2e056a48ca8c922298b7a9e88b',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_14;

  -- Property 15: Old Town Heritage Architectural Manor (Savannah, GA)
  -- 3D House Asset: Low Poly Home 2 (Sketchfab: f5e7be986a524c3c976c726a9f2b2061)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_marcus_id,
    'Old Town Heritage Architectural Manor',
    'Savannah, GA 31401',
    '$2,150,000',
    'Historic antebellum brick manor with wrought-iron balconies, private courtyard gardens, restored heart-pine flooring, and 12-foot double-hung sash windows.',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-home-2-f5e7be986a524c3c976c726a9f2b2061',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_15;

  -- Property 16: The Victorian Gothic Historic Mansion (New Orleans, LA)
  -- 3D House Asset: Gothic Victorian Heritage Manor Estate
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_isabella_id,
    'The Victorian Gothic Historic Mansion',
    'Garden District, New Orleans, LA 70130',
    '$3,890,000',
    'Stately Garden District mansion featuring gothic architecture, soaring turrets, original gas-flame lanterns, ornate plaster molding, and secluded magnolia grounds.',
    'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/haunted_house.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_16;

  -- Property 17: SoHo Industrial Modern Loft (SoHo, New York, NY)
  -- 3D House Asset: Low Poly Stylized Home (Sketchfab: ca64053dca474ff2825eedaaf8eb98d1)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_marcus_id,
    'SoHo Industrial Modern Loft',
    'SoHo, New York, NY 10012',
    '$3,450,000',
    'Cast-iron building corner loft with barrel-vaulted brick ceilings, oversized Corinthian columns, polished concrete floors, and custom minimalist steel architectural framing.',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-stylized-home-ca64053dca474ff2825eedaaf8eb98d1',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_17;

  -- Property 18: Skyline Terrace Duplex Penthouse (Chicago, IL)
  -- 3D House Asset: Low Poly Medieval House 1 (Sketchfab: 81b8d567c94945059918e0bf303c8310)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_isabella_id,
    'Skyline Terrace Duplex Penthouse',
    'Gold Coast, Chicago, IL 60611',
    '$2,780,000',
    'Luxury two-story duplex penthouse overlooking Lake Michigan. Features custom floating glass staircase, 800 sq ft private terrace with outdoor fireplace, and smart Lutron automation.',
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-medieval-house-1-81b8d567c94945059918e0bf303c8310',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_18;

  -- Property 19: Grand Arch Modernist Passageway Villa (Palm Springs, CA)
  -- 3D House Asset: Geometric Architectural Bridge Villa (Road Gap Building)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_sarah_id,
    'Grand Arch Modernist Passageway Villa',
    'Palm Springs, CA 92264',
    '$3,120,000',
    'Mid-century modern desert oasis with iconic structural archway, sunken fire pit lounge, saltwater lap pool, and panoramic views of the San Jacinto mountain range.',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/BabylonJS/Assets/master/meshes/Buildings/road gap.glb',
    false,
    'pending'::public.property_status
  )
  returning id into v_prop_19;

  -- Property 20: Highland Geometric Eco-Residence (Portland, OR)
  -- 3D House Asset: Low Poly Wooden Cabine (Sketchfab: 5cb73d080fcb4968b50c6d4b040a04e6)
  insert into public.properties (
    homeowner_id,
    name,
    location,
    price,
    description,
    image_path,
    model_path,
    is_featured,
    status
  )
  values (
    v_elena_id,
    'Highland Geometric Eco-Residence',
    'Portland, OR 97201',
    '$1,980,000',
    'LEED Platinum certified hillside residence featuring green roof garden, geo-thermal heating, triple-pane floor-to-ceiling glass, and sustainable western red cedar siding.',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    'https://sketchfab.com/3d-models/low-poly-wooden-cabine-5cb73d080fcb4968b50c6d4b040a04e6',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_20;

  -- 5. Seed Property Images (At least 3 high-resolution images per listing)
  -- Property 1 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_1, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_1, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_1, 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80', 2),
    (v_prop_1, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80', 3);

  -- Property 2 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_2, 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_2, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_2, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 3 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_3, 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_3, 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_3, 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 4 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_4, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_4, 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_4, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 5 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_5, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_5, 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_5, 'https://images.unsplash.com/photo-1600573472591-ee6b68d14c68?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 6 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_6, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_6, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_6, 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 7 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_7, 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_7, 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_7, 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 8 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_8, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_8, 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_8, 'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 9 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_9, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_9, 'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_9, 'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 10 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_10, 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_10, 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_10, 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 11 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_11, 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_11, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_11, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 12 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_12, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_12, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_12, 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 13 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_13, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_13, 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_13, 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 14 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_14, 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_14, 'https://images.unsplash.com/photo-1598228723793-52759bba239c?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_14, 'https://images.unsplash.com/photo-1576941089067-2de3c901e126?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 15 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_15, 'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_15, 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_15, 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 16 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_16, 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_16, 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_16, 'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 17 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_17, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_17, 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_17, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 18 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_18, 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_18, 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_18, 'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 19 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_19, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_19, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_19, 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 20 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_20, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_20, 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_20, 'https://images.unsplash.com/photo-1598228723793-52759bba239c?auto=format&fit=crop&w=1200&q=80', 2);

  -- 6. Seed Favorites
  insert into public.favorites (profile_id, property_id)
  values
    (v_chen_id, v_prop_1),
    (v_chen_id, v_prop_2),
    (v_chen_id, v_prop_3),
    (v_chen_id, v_prop_13),
    (v_taylor_id, v_prop_1),
    (v_taylor_id, v_prop_4),
    (v_taylor_id, v_prop_6),
    (v_taylor_id, v_prop_14),
    (v_wilson_id, v_prop_2),
    (v_wilson_id, v_prop_7),
    (v_wilson_id, v_prop_17),
    (v_wilson_id, v_prop_20)
  on conflict (profile_id, property_id) do nothing;

  -- 7. Seed Inquiries
  insert into public.inquiries (
    homeowner_id,
    property_id,
    property_name,
    property_image,
    buyer_email,
    message,
    is_read
  )
  values
    (
      v_sarah_id,
      v_prop_1,
      'The Glass Horizon Villa',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      'david.chen@buyer.com',
      'Hello Sarah, I am captivated by the 3D model and architecture of The Glass Horizon Villa. Is it possible to schedule a private tour this coming Saturday?',
      false
    ),
    (
      v_vance_id,
      v_prop_2,
      'Neo Tokyo Skyline Penthouse',
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
      'david.chen@buyer.com',
      'Hi Alexander, does the Shibuya penthouse include parking and private rooftop terrace privileges? Looking forward to your response.',
      true
    ),
    (
      v_elena_id,
      v_prop_4,
      'Villa Serena Waterfront Estate',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      'olivia.taylor@buyer.com',
      'Dear Elena, I am interested in placing an offer for Villa Serena. Are the yacht dock dimensions suitable for a 65ft vessel?',
      false
    ),
    (
      v_marcus_id,
      v_prop_13,
      'Azure Coastline Mediterranean Villa',
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
      'james.wilson@buyer.com',
      'Hello Marcus, could you share more details regarding the private bluff staircase and beach access permit for the Malibu compound?',
      false
    ),
    (
      v_isabella_id,
      v_prop_14,
      'Emerald Valley Alpine Resort Estate',
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
      'olivia.taylor@buyer.com',
      'Hi Isabella, is the guest lodge equipped with separate utilities and radiant floor heating for winter rental capability?',
      true
    );

  -- 8. Seed Support Tickets
  insert into public.support_tickets (
    profile_id,
    user_email,
    subject,
    description,
    status
  )
  values
    (
      v_chen_id,
      'david.chen@buyer.com',
      'Inquiry on 3D AR Model View Scaling',
      'When viewing the 3D model in AR mode on Android, the scale calibration took a moment to adjust. Is there a manual zoom scale locking feature?',
      'in_progress'::public.ticket_status
    ),
    (
      v_sarah_id,
      'sarah.jenkins@luxuryhomes.com',
      'Featured Listing Promotion Duration',
      'Could you confirm how long the Glass Horizon Villa will remain on the featured banner rotating carousel?',
      'resolved'::public.ticket_status
    ),
    (
      v_taylor_id,
      'olivia.taylor@buyer.com',
      'Account Notification Settings Confirmation',
      'Requesting confirmation that email alerts for new waterfront listings in Miami are active.',
      'new'::public.ticket_status
    ),
    (
      v_marcus_id,
      'marcus.thorne@archilux.com',
      'High-Resolution GLB Asset Caching',
      'Our architectural firm uploaded the twin Mediterranean villa model. We wanted to verify if the asset is served via regional CDN edge caching.',
      'resolved'::public.ticket_status
    );

end $$;
