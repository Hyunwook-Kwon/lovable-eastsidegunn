# Open Questions — Polish for Public Visibility

## polish-for-public — 2026-05-20

- [ ] **Demo GIF: sprite background transparency** — The sprites are RGBA PNGs (confirmed `hasAlpha: yes`). GIF only supports 1-bit transparency. If sprite backgrounds are not pure single-color, the GIF may have artifacts. Need to check if sprites have transparent BG or bathroom-stall BG baked in. If baked-in BG, the GIF will look fine. If transparent, need to composite onto a solid color first. — *Affects Task 1.1 ffmpeg pipeline.*

- [ ] **Demo GIF: use chip (default) sprites only, or show food-change too?** — Current plan uses chip/default sprites for the panic→calm cycle. A more ambitious GIF could also show the `changing` state (food swap). Decided: keep simple (one food cycle) unless user wants to showcase food variety. — *User preference, low stakes.*

- [ ] **Social preview image upgrade** — Currently auto-generated OpenGraph. Could set a custom 1280×640 social preview using the screenshot or a composed image with demo GIF frames. Decided: skip for now (LOW priority), can add later. — *Nice-to-have, not blocking.*

- [ ] **Librarian agent output** — bg_f2ea600f results pending. May surface recommendations that conflict with our "skip CoC/PR template" decisions. Will integrate if proportional, ignore if over-engineering. — *Non-blocking, additive only.*
