"""Çığlıkçı oyun modelinin ağırlık yardımcıları (7.3): uzaklık + jeodezik doğrulama, ağız torbası.

screamer_game.py içe aktarır. Uzun kollar uyluğun yanında sarktığı için yalnız öklid uzaklığıyla ağırlık
verilince kalça/uyluk derisi önkol ağırlığı alıyor, kol yana açılınca gövdeden sivri çıkıntı çekiyordu;
jeodezik (yüzey üstü) doğrulama bunu önler.
"""
import walker_game as wg


def weight_multi(obj, segments: dict, keep: int = 3, power: float = 4.0, geo: bool = False) -> None:
    """Kemik parçalarına uzaklıkla ağırlık. geo=True: yüzey üzerinden (jeodezik) doğrulama — uzun kol
    uyluğun yanında sarktığı için kalça/uyluk derisi el/önkol ağırlığı almasın (kol yana açılınca gövdeden
    sivri çıkıntı çekiyordu). Kemik adayı, jeodezik uzaklığı öklidin GEO_SLACK katını aşarsa elenir."""
    groups = {n: obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n) for n in segments}
    mw = obj.matrix_world
    pos = [mw @ v.co for v in obj.data.vertices]
    names = list(segments)
    dist = [[min(wg._seg_dist(p, a, b) for a, b in segments[n]) for n in names] for p in pos]
    allowed = geo_allowed(obj, pos, dist, names) if geo else None
    for i in range(len(pos)):
        cand = [(1.0 / max(d, 0.004) ** power, names[j]) for j, d in enumerate(dist[i])
                if allowed is None or allowed[i][j]]
        scored = sorted(cand, reverse=True)[:keep]
        total = sum(w for w, _ in scored)
        for w, n in scored:
            groups[n].add([i], w / total, "REPLACE")


GEO_SLACK = (1.6, 0.06)   # jeodezik <= öklid * 1.6 + 0.06 m


def geo_allowed(obj, pos, dist, names):
    """Her kemik için çekirdek köşelerden (kemik çizgisine en yakın deri) çok kaynaklı Dijkstra."""
    import heapq
    n = len(pos)
    nbr = [[] for _ in range(n)]
    for e in obj.data.edges:
        a, b = e.vertices
        ln = (pos[a] - pos[b]).length
        nbr[a].append((b, ln))
        nbr[b].append((a, ln))
    nearest = [min(range(len(names)), key=lambda j, i=i: dist[i][j]) for i in range(n)]
    allowed = [[False] * len(names) for _ in range(n)]
    for j in range(len(names)):
        own = [i for i in range(n) if nearest[i] == j]
        if not own:
            continue
        dmin = min(dist[i][j] for i in own)
        seeds = [i for i in own if dist[i][j] <= dmin * 1.25 + 0.004]
        geo = {i: 0.0 for i in seeds}
        heap = [(0.0, i) for i in seeds]
        cutoff = 0.7
        while heap:
            d, i = heapq.heappop(heap)
            if d > geo.get(i, 1e9) or d > cutoff:
                continue
            for k, ln in nbr[i]:
                nd = d + ln
                if nd < geo.get(k, 1e9):
                    geo[k] = nd
                    heapq.heappush(heap, (nd, k))
        for i in range(n):
            g = geo.get(i)
            allowed[i][j] = g is not None and g <= dist[i][j] * GEO_SLACK[0] + GEO_SLACK[1]
    for i in range(n):          # hiçbir aday geçmediyse en yakın kemik
        if not any(allowed[i]):
            allowed[i][nearest[i]] = True
    return allowed


def weight_bag(obj) -> None:
    """Ağız torbası: jaw_w → jaw (w) + Head (1 - w)."""
    src = obj.vertex_groups["jaw_w"]
    jaw, head = obj.vertex_groups.new(name="jaw"), obj.vertex_groups.new(name="Head")
    for v in obj.data.vertices:
        w = next((g.weight for g in v.groups if g.group == src.index), 0.0)
        jaw.add([v.index], w, "REPLACE")
        head.add([v.index], 1.0 - w, "REPLACE")
    obj.vertex_groups.remove(src)
