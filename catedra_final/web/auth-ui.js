// Login, session state and user management. Business operations live in app.js.
let currentUser=null,allowedPages=[],setupMode=false,appUsers=[];
const roleLabels={gerencia:'Gerencia',cajero:'Cajero',inventario:'Inventario'};
function roleLabel(role){return roleLabels[role]||role}
function showAuth(setup=false){
  currentUser=null;allowedPages=[];db=null;cart=[];selectedEmployee='';selectedClient='';setupMode=setup;
  if($('#modal').open)$('#modal').close();$('#modal-fields').innerHTML='';
  document.body.classList.remove('signed-in');document.body.classList.remove('auth-loading');
  $('#view').innerHTML='';$('#error').hidden=true;$('#auth-error').textContent='';
  $('#auth-title').textContent=setup?'Crea tu cuenta de gerencia':'Qué bueno verte de nuevo.';
  $('#auth-description').textContent=setup?'Este primer acceso permite administrar las cuentas de tu equipo.':'Ingresa con tu usuario y contraseña para continuar.';
  $('#auth-fields').innerHTML=(setup?field('Tu nombre','name','text','maxlength="100" autocomplete="name" required'):'')+field('Usuario','username','text','minlength="3" maxlength="40" autocomplete="username" pattern="[a-z0-9_.-]{3,40}" required')+field('Contraseña','password','password',`minlength="${setup?10:1}" maxlength="128" autocomplete="${setup?'new-password':'current-password'}" required`)+(setup?field('Repite tu contraseña','confirmation','password','minlength="10" maxlength="128" autocomplete="new-password" required'):'');
  $('#auth-submit').textContent=setup?'Crear cuenta y entrar':'Iniciar sesión';$('#auth-submit').disabled=false;
}
function updateAccount(){
  $('#auth-fields').innerHTML='';
  document.body.classList.add('signed-in');document.body.classList.remove('auth-loading');
  document.querySelectorAll('nav button[data-page]').forEach(b=>b.hidden=!allowedPages.includes(b.dataset.page));
  $('#account-name').textContent=currentUser.name;
  $('#account-role').textContent=roleLabel(currentUser.role)+' · '+currentUser.username;
  $('#account-avatar').textContent=currentUser.name.split(/\s+/).slice(0,2).map(n=>n[0]).join('').toUpperCase();
  $('#connection').textContent='● Conectado';
}
async function boot(){
  try{const s=await api('/api/session');token=s.token;
    if(!s.user){showAuth(s.setup);return}
    currentUser=s.user;allowedPages=s.pages;if(!allowedPages.includes(page))page=allowedPages[0];updateAccount();await load();
  }catch(e){showAuth(false);$('#auth-error').textContent=e.message;$('#auth-submit').disabled=true;$('#auth-fields').innerHTML='<button type="button" class="secondary" data-action="reconnect-auth">Reintentar conexión</button>'}
}
function usersHTML(){return heading('Tu equipo, con su propio acceso.','Crea cuentas y asigna permisos según el trabajo de cada persona.','<button class="primary" data-action="new-user">＋ Nuevo usuario</button>')+`<div class="role-cards"><div class="panel"><h2>Gerencia</h2><p>Acceso completo, reportes, anulaciones y administración de cuentas.</p></div><div class="panel"><h2>Cajero</h2><p>Punto de venta, consulta de ventas y registro de clientes.</p></div><div class="panel"><h2>Inventario</h2><p>Productos, entradas, precios, stock crítico y movimientos.</p></div></div><div class="panel section-gap">${table(['NOMBRE','USUARIO','ROL','ESTADO',''],appUsers.map(u=>`<tr><td>${esc(u.name)}</td><td>${esc(u.username)} ${u.id===currentUser.id?'(tú)':''}</td><td>${roleLabel(u.role)}</td><td>${pill(u.active?'ACTIVO':'INACTIVO')}</td><td>${u.id!==currentUser.id?`<button class="link" data-action="user-status" data-id="${u.id}">${u.active?'Desactivar':'Activar'}</button>`:'Cuenta actual'}</td></tr>`))}</div>`}
async function loadUsers(){appUsers=await api('/api/users');if(page==='users')render()}
$('#auth-form').onsubmit=async e=>{
  e.preventDefault();const data=Object.fromEntries(new FormData(e.target));$('#auth-error').textContent='';
  if(setupMode&&data.password!==data.confirmation){$('#auth-error').textContent='Las contraseñas no coinciden.';return}
  $('#auth-submit').disabled=true;
  try{const s=await api(setupMode?'/api/auth/setup':'/api/auth/login',data);token=s.token;currentUser=s.user;allowedPages=s.pages;page=allowedPages[0];$('#auth-form').reset();updateAccount();await load()}
  catch(err){$('#auth-error').textContent=err.message;$('#auth-submit').disabled=false}
};
document.addEventListener('click',async e=>{
  const b=e.target.closest('button');if(!b)return;
  if(b.dataset.page==='users'&&allowedPages.includes('users')){try{await loadUsers()}catch(err){toast(err.message)}}
  const action=b.dataset.action;
  try{
    if(action==='reconnect-auth')return boot();
    if(action==='logout'){if(busy)return;await api('/api/auth/logout',{});token='';appUsers=[];await boot();return}
    if(action==='password')modal('Cambiar mi contraseña',field('Contraseña actual','current_password','password','autocomplete="current-password" maxlength="128" required')+field('Nueva contraseña','password','password','minlength="10" maxlength="128" autocomplete="new-password" required')+field('Repite la nueva contraseña','confirmation','password','minlength="10" maxlength="128" autocomplete="new-password" required'),async d=>{if(d.password!==d.confirmation)throw Error('Las contraseñas no coinciden.');await api('/api/auth/password',d);toast('Contraseña actualizada. Inicia sesión de nuevo.');token='';await boot()});
    if(action==='new-user'&&currentUser.role==='gerencia')modal('Nuevo usuario',field('Nombre completo','name','text','maxlength="100" required')+field('Usuario','username','text','minlength="3" maxlength="40" pattern="[a-z0-9_.-]{3,40}" autocomplete="off" required')+'<label for="f-role">Rol</label><select name="role" id="f-role"><option value="cajero">Cajero</option><option value="inventario">Inventario</option><option value="gerencia">Gerencia</option></select>'+field('Contraseña inicial','password','password','minlength="10" maxlength="128" autocomplete="new-password" required'),async d=>{await api('/api/users',d);toast('Usuario creado. Ya puede iniciar sesión.');await loadUsers()});
    if(action==='user-status'&&currentUser.role==='gerencia'){const u=appUsers.find(u=>u.id===Number(b.dataset.id));modal((u.active?'Desactivar':'Activar')+' cuenta',`<p>${esc(u.name)} (${esc(u.username)})</p><p>${u.active?'Se cerrarán sus sesiones y no podrá iniciar sesión. Podrás activar la cuenta nuevamente.':'La persona podrá volver a iniciar sesión con su contraseña.'}</p>`,async()=>{await api('/api/users/status',{id:u.id,active:!u.active});toast('Estado de la cuenta actualizado.');await loadUsers()})}
  }catch(err){toast(err.message)}
});
boot();
