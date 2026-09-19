const databaseUrl = process.env.DATABASE_URL?.trim();
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
const hasPlaceholderKey = !serviceRoleKey || serviceRoleKey.startsWith('replace-with-');
const otpTableUrl = databaseUrl?.replace(/\/Student\/?$/, '/student_email_otps');
const adminPresenceUrl = databaseUrl?.replace(/\/Student\/?$/, '/admin_presence');

if (!databaseUrl || hasPlaceholderKey) {
  console.warn('DATABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for student auth.');
}

function headers(prefer) {
  return {
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    'Content-Type': 'application/json',
    ...(prefer ? { Prefer: prefer } : {}),
  };
}

async function supabaseRequest(path, options = {}, requestUrl = databaseUrl) {
  if (!databaseUrl || hasPlaceholderKey) {
    const error = new Error('Set the real SUPABASE_SERVICE_ROLE_KEY in lms-backend/.env.');
    error.statusCode = 500;
    throw error;
  }

  const response = await fetch(`${requestUrl}${path}`, {
    ...options,
    headers: { ...headers(options.prefer), ...(options.headers ?? {}) },
  });
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    const error = new Error(body?.message ?? body?.hint ?? 'Supabase request failed.');
    error.statusCode = response.status >= 500 ? 502 : response.status;
    throw error;
  }
  return body;
}

export async function findStudentByUsername(username) {
  const students = await supabaseRequest(
    `?select=id,full_name,mobile,email,username,password_hash,Is_verify,device_id,device_name,last_login_at&username=eq.${encodeURIComponent(username)}&limit=1`,
  );
  return students[0] ?? null;
}

export async function findStudentByLogin(username) {
  return findStudentByUsername(username);
}

export async function createStudent(student) {
  const students = await supabaseRequest('', {
    method: 'POST',
    prefer: 'return=representation',
    body: JSON.stringify({
      full_name: student.fullName,
      mobile: student.mobile,
      email: student.email,
      username: student.username,
      password_hash: student.passwordHash,
      Is_verify: false,
    }),
  });
  return students[0];
}

export async function deleteStudent(username) {
  await supabaseRequest(`?username=eq.${encodeURIComponent(username)}`, {
    method: 'DELETE',
  });
}

export async function saveEmailOtp({ username, email, otpHash, expiresAt }) {
  await supabaseRequest('', {
    method: 'POST',
    prefer: 'return=minimal',
    body: JSON.stringify({ username, email, otp_hash: otpHash, expires_at: expiresAt }),
  }, otpTableUrl);
}

export async function findLatestEmailOtp(username) {
  return supabaseRequest(
    `?select=id,otp_hash,expires_at,attempts,used_at&username=eq.${encodeURIComponent(username)}&used_at=is.null&order=created_at.desc&limit=1`,
    {},
    otpTableUrl,
  ).then((rows) => rows[0] ?? null);
}

export async function markEmailOtpUsed(id) {
  await supabaseRequest(`?id=eq.${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: JSON.stringify({ used_at: new Date().toISOString() }),
  }, otpTableUrl);
}

export async function incrementEmailOtpAttempts(id, attempts) {
  await supabaseRequest(`?id=eq.${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: JSON.stringify({ attempts: attempts + 1 }),
  }, otpTableUrl);
}

export async function activateStudent(username) {
  await supabaseRequest(`?username=eq.${encodeURIComponent(username)}`, {
    method: 'PATCH',
    body: JSON.stringify({ Is_verify: true }),
  });
}

export async function updateLastLogin(username) {
  await supabaseRequest(`?username=eq.${encodeURIComponent(username)}`, {
    method: 'PATCH',
    body: JSON.stringify({ last_login_at: new Date().toISOString() }),
  });
}

export async function upsertAdminPresence({ username, deviceName, isOnline = true }) {
  try {
    await supabaseRequest('', {
      method: 'POST',
      prefer: 'resolution=merge-duplicates,return=minimal',
      body: JSON.stringify({
        admin_username: username,
        device_name: deviceName ?? null,
        is_online: isOnline,
        last_seen_at: new Date().toISOString(),
      }),
    }, adminPresenceUrl);
  } catch (err) {
    // Table public.admin_presence is optional in Supabase
    if (process.env.DEBUG_PRESENCE) {
      console.warn(`Admin presence table notice: ${err.message}`);
    }
  }
}
