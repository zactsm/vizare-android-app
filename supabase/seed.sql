-- ============================================================
-- Vizare Real Estate Database Seed File
-- Supabase Fixtures & Seed Data
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
      )
    on conflict (id) do update set
      email = excluded.email,
      raw_user_meta_data = excluded.raw_user_meta_data,
      updated_at = now();
  end if;
exception
  when others then
    -- Auth table might not be directly editable in certain hosted environments; continue seeding profiles
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

-- 4. Seed Properties
do $$
declare
  v_sarah_id bigint;
  v_vance_id bigint;
  v_elena_id bigint;
  v_chen_id bigint;
  v_taylor_id bigint;
  
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
begin
  select id into v_sarah_id from public.profiles where email = 'sarah.jenkins@luxuryhomes.com';
  select id into v_vance_id from public.profiles where email = 'alexander.vance@vancerealty.com';
  select id into v_elena_id from public.profiles where email = 'elena.rostova@azureestates.com';
  select id into v_chen_id from public.profiles where email = 'david.chen@buyer.com';
  select id into v_taylor_id from public.profiles where email = 'olivia.taylor@buyer.com';

  -- Property 1: The Glass Horizon Villa (Featured & Approved)
  -- 3D Asset: Sheen Wood Leather Sofa (PBR Designer Furniture)
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
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenWoodLeatherSofa/glTF-Binary/SheenWoodLeatherSofa.glb',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_1;

  -- Property 2: Neo Tokyo Skyline Penthouse (Featured & Approved)
  -- 3D Asset: Littlest Tokyo (Full Multistory Architectural Diorama with Animation)
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
    'Spectacular multi-level urban penthouse diorama overlooking the neon skyline. Features automated smart home climate systems, private sky deck, and bespoke architectural woodwork.',
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/LittlestTokyo.glb',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_2;

  -- Property 3: Nordic Minimalist Residence (Featured & Approved)
  -- 3D Asset: Sheen Chair (Scandinavian Velvet Armchair)
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
    'Modern Scandinavian architectural retreat crafted with sustainable Douglas fir beams, polished concrete radiant floors, and floor-to-ceiling forest views. Includes bespoke designer armchair model.',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb',
    true,
    'approved'::public.property_status
  )
  returning id into v_prop_3;

  -- Property 4: Villa Serena Waterfront Estate (Approved)
  -- 3D Asset: Lantern (Historic Courtyard Entryway Lighting)
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
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Lantern/glTF-Binary/Lantern.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_4;

  -- Property 5: The Modernist Cantilever House (Approved)
  -- 3D Asset: Anisotropy Barn Lamp (Industrial Architectural Fixture)
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
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/AnisotropyBarnLamp/glTF-Binary/AnisotropyBarnLamp.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_5;

  -- Property 6: The Obsidian Contemporary Penthouse (Approved)
  -- 3D Asset: A Beautiful Game (Grandmaster Marble Chess Lounge Set)
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
    'High-floor Tribeca loft penthouse with 14-foot ceilings, direct key-elevator access, private wrap-around terrace, custom marble chess lounge, and breathtaking river vistas.',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/ABeautifulGame/glTF-Binary/ABeautifulGame.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_6;

  -- Property 7: Heritage Craftsman Villa & Studio (Approved)
  -- 3D Asset: Antique Camera with Wooden Tripod
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
    'Elegantly restored 1920s Craftsman residence featuring handcrafted mahogany joinery, original river rock fireplace, vintage photography study studio, and detached guest carriage house.',
    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/AntiqueCamera/glTF-Binary/AntiqueCamera.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_7;

  -- Property 8: Celestial Horizon Gallery Loft (Approved)
  -- 3D Asset: Astronaut Explorer Statue (Contemporary Art Lounge)
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
    'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    false,
    'approved'::public.property_status
  )
  returning id into v_prop_8;

  -- Property 9: Sunset Ridge Modern Estate (Pending)
  -- 3D Asset: Iridescence Lamp (Prismatic Ambient Lighting)
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
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/IridescenceLamp/glTF-Binary/IridescenceLamp.glb',
    false,
    'pending'::public.property_status
  )
  returning id into v_prop_9;

  -- Property 10: Pinecrest Alpine Sanctuary (Draft)
  -- 3D Asset: BoomBox (Retro Hi-Fi Audio Lounge)
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
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/BoomBox/glTF-Binary/BoomBox.glb',
    false,
    'draft'::public.property_status
  )
  returning id into v_prop_10;

  -- Property 11: Cyberpunk Artefact Penthouse Gallery (Sold)
  -- 3D Asset: Damaged Helmet (Collector''s Sci-Fi Sculpture)
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
    'Exclusive SoMa tech penthouse with high-security biometric entry, private roof garden, and display gallery featuring futuristic battle-worn helmet artifact.',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/DamagedHelmet/glTF-Binary/DamagedHelmet.glb',
    false,
    'sold'::public.property_status
  )
  returning id into v_prop_11;

  -- Property 12: Rolling Hills Farmstead & Manor (Rejected)
  -- 3D Asset: Cesium Milk Truck (Historic Estate Supply Vehicle)
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
    'Pastoral country estate with 10 rolling acres, equestrian stables, heritage farm logistics barn, and historic supply vehicle model.',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/CesiumMilkTruck/glTF-Binary/CesiumMilkTruck.glb',
    false,
    'rejected'::public.property_status
  )
  returning id into v_prop_12;

  -- 5. Seed Property Images (Galleries)
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
    (v_prop_3, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_3, 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 4 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_4, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_4, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_4, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 5 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_5, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_5, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_5, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 6 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_6, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_6, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_6, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 7 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_7, 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_7, 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_7, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 8 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_8, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_8, 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80', 1),
    (v_prop_8, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 2);

  -- Property 9 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_9, 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_9, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 1);

  -- Property 10 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_10, 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_10, 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 1);

  -- Property 11 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_11, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_11, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80', 1);

  -- Property 12 Images
  insert into public.property_images (property_id, image_url, sort_order)
  values
    (v_prop_12, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80', 0),
    (v_prop_12, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80', 1);

  -- 6. Seed Favorites
  insert into public.favorites (profile_id, property_id)
  values
    (v_chen_id, v_prop_1),
    (v_chen_id, v_prop_2),
    (v_chen_id, v_prop_3),
    (v_taylor_id, v_prop_1),
    (v_taylor_id, v_prop_4),
    (v_taylor_id, v_prop_6)
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
    );

end $$;
