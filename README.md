# Site Blu Padel

Site estático. Não precisa de Node nem de servidor próprio.

- `index.html`: o site inteiro, com CSS e JavaScript embutidos.
- `admin.html`: o painel de torneios (login e banco no Supabase).
- `assets/img/`: as fotos.
- `supabase/setup.sql`: cria a tabela, as regras de segurança e o bucket das capas no Supabase.

Para publicar, envie `index.html`, `admin.html` e a pasta `assets/` para qualquer hospedagem de site estático, como Hostinger, Netlify, Vercel ou Cloudflare Pages.

## Ver localmente

```bash
python -m http.server 5173
```

Depois abra http://localhost:5173. Os arquivos precisam ser servidos por um servidor (mesmo que local), não abertos com duplo clique, por causa dos módulos 3D.

## Conectar ao Supabase

1. Crie um projeto em supabase.com.
2. Em **SQL Editor**, cole o conteúdo de `supabase/setup.sql` e clique em **Run**.
3. Em **Authentication > Users > Add user**, crie o usuário do painel:
   - E-mail: `bluepadel@blupadel.com.br` (no painel, basta digitar `bluepadel`).
   - Marque **Auto Confirm User**.
   - Use uma senha com pelo menos 6 caracteres, que é o mínimo do Supabase.
4. Rode no SQL Editor a linha que está no fim do `setup.sql` (`insert into public.admins ...`). Ela dá permissão de administrador a esse usuário.
5. Em **Settings > API**, copie a **Project URL** e a chave **anon public**. Cole as duas em `window.BP_SUPABASE`, no topo do `index.html` e do `admin.html`.

Sem essa configuração, o site continua funcionando e mostra os cartazes fixos dos circuitos já realizados.

## Como funciona o painel de torneios

- **Torneio publicado e dentro da data:** o site mostra uma barra "Inscrições abertas" no topo e um ponto piscando em "Torneios". O cartaz aparece em destaque com datas, valor e contagem regressiva.
- **Com link de inscrição:** o botão fica "Fazer minha inscrição" e abre o link. Sem link, o botão vira "Quero jogar o próximo torneio" e abre o WhatsApp.
- **Depois da data final:** o torneio entra sozinho na pilha "Circuitos já realizados".

## Animações e "reduzir movimento"

Se o sistema do visitante pede menos movimento (Windows com "Efeitos de animação" desligado, ou iPhone com "Reduzir movimento"), o site mostra versões estáticas.

Para ver tudo animado mesmo assim, abra com `?anim=1`. Para voltar ao normal, use `?anim=0`.
