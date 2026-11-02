import QtQuick

// ListModel que se actualiza en sitio a partir de un array JS (`sync(rows)`):
//  - conserva la posicion del scroll (no se reconstruye la lista en cada muestra)
//  - mueve/inserta/quita solo lo que cambia, para que el ListView pueda animar los reordenamientos
//  - opcionalmente suaviza los valores numericos `v` y `v2` entre muestras (media exponencial)
ListModel {
    id: root
    dynamicRoles: true

    property string key: "id"            // campo unico de cada fila
    property var template: ({})          // campos y valores por defecto (todas las filas tienen la misma forma)
    property bool sortDesc: false        // true: ordena por (v + v2) de mayor a menor
    property real smoothing: 0           // 0 = valores crudos; 0.5 = cada muestra pesa la mitad
    signal synced()

    function norm(r, old) {
        const o = {};
        for (const f in template) {
            let v = r[f] !== undefined ? r[f] : template[f];
            if (old && smoothing > 0 && (f === "v" || f === "v2") && typeof v === "number")
                v = old[f] + (v - old[f]) * (1 - smoothing);
            o[f] = v;
        }
        return o;
    }

    function sync(rows) {
        const oldByKey = {};
        for (let i = 0; i < count; i++) {
            const e = get(i);
            oldByKey[e[key]] = e;
        }
        const want = [];
        for (const r of rows) want.push(norm(r, oldByKey[r[key]]));
        if (sortDesc) want.sort((a, b) => ((b.v || 0) + (b.v2 || 0)) - ((a.v || 0) + (a.v2 || 0)));

        const wanted = {};
        for (const w of want) wanted[w[key]] = true;
        for (let i = count - 1; i >= 0; i--)
            if (!wanted[get(i)[key]]) remove(i);

        for (let i = 0; i < want.length; i++) {
            const w = want[i];
            if (i < count && get(i)[key] === w[key]) { set(i, w); continue; }
            let j = -1;
            for (let k = i + 1; k < count; k++)
                if (get(k)[key] === w[key]) { j = k; break; }
            if (j >= 0) { move(j, i, 1); set(i, w); }
            else insert(i, w);
        }
        synced();
    }
}
