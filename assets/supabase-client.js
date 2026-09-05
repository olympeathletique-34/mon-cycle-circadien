/* ══════════ CONFIGURATION SUPABASE ══════════
   Remplis ces deux valeurs avec celles de ton projet Supabase :
   Dashboard → Project Settings → API → "Project URL" et "anon public" key.
   Ces valeurs sont publiques par nature (protégées par les policies RLS
   côté base de données) : aucun risque à les laisser dans le code client. */
const SUPABASE_URL = "https://fdwgzlfhorohmqtfnmnq.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkd2d6bGZob3JvaG1xdGZubW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1NDcyNTIsImV4cCI6MjEwNDEyMzI1Mn0.Us6BCchUcNx_kjSlaqL8ODUXbgqCwZWIoOjhdSxS3hk";

const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
});

/* Envoie un lien de connexion (magic link) à l'adresse donnée. */
async function envoyerLienMagique(email, redirectTo){
  return sb.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: redirectTo }
  });
}

async function deconnexion(){
  return sb.auth.signOut();
}

async function sessionActuelle(){
  const { data } = await sb.auth.getSession();
  return data.session || null;
}

/* Récupère (ou crée si absent) le profil de l'utilisateur connecté. */
async function profilActuel(){
  const session = await sessionActuelle();
  if(!session) return null;
  const { data, error } = await sb
    .from("profiles")
    .select("*")
    .eq("id", session.user.id)
    .maybeSingle();
  if(error){ console.error(error); return null; }
  if(data) return data;
  // Filet de sécurité si le trigger auto-création n'a pas encore tourné.
  const { data: cree, error: err2 } = await sb
    .from("profiles")
    .insert({ id: session.user.id, email: session.user.email })
    .select()
    .single();
  if(err2){ console.error(err2); return null; }
  return cree;
}
