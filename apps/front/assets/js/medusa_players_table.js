const pos = document.getElementById('reference_point');
const apply_filters1 = document.getElementById("apply_filters1");
const apply_filters2 = document.getElementById("apply_filters2");

const next1 = document.getElementById("next1");
const next2 = document.getElementById("next2");
const before1 = document.getElementById("before1");
const before2 = document.getElementById("before2");

const maxRows = 50
let index_rows = parseInt(document.getElementById("index_rows").textContent);
let total_rows = parseInt(document.getElementById("total_rows").textContent);

apply_filters1.addEventListener('click', applyFilters);
apply_filters2.addEventListener('click', applyFilters);

next1.addEventListener('click', nextPage);
next2.addEventListener('click', nextPage);
before1.addEventListener('click', prevPage);
before2.addEventListener('click', prevPage);

function updateValue(e) {
  log.textContent = e.target.value;
}

function applyFilters(e) {
    const newRows = Array.from(document.getElementById('medusa_player_body').rows)
	  .map(rowHidden)
	  .sort((tuple1, tuple2) => tuple1[1] > tuple2[1])

    total_rows = newRows.reduce((acc, x) => x[1] === false ? acc+1 : acc, 0)
    document.getElementById("total_rows").textContent = total_rows

    index_rows = 0
    document.getElementById("index_rows").textContent = index_rows

    const rowsIndexed = createIndex(index_rows, total_rows, maxRows, newRows.map((x) => x[0]))
    document.getElementById('medusa_player_body').replaceWith(newTBody(rowsIndexed))

    const details_filter = document.getElementById("details_filters");
    details_filter.open = false

}

function nextPage(e) {
    if (index_rows + maxRows <= total_rows) {
	const rows = Array.from(document.getElementById('medusa_player_body').rows)
	index_rows = index_rows + maxRows
	document.getElementById("index_rows").textContent = index_rows
	const details_filter = document.getElementById("details_filters");
	details_filter.open = false
	const rowsIndexed = createIndex(index_rows, total_rows, maxRows, rows)
	document.getElementById('medusa_player_body').replaceWith(newTBody(rowsIndexed))
    }
}


function prevPage(e) {
    if (index_rows > 0) {
	const rows = Array.from(document.getElementById('medusa_player_body').rows)
	index_rows = index_rows - maxRows
	document.getElementById("index_rows").textContent = index_rows
	const details_filter = document.getElementById("details_filters");
	details_filter.open = false
	const rowsIndexed = createIndex(index_rows, total_rows, maxRows, rows)
	document.getElementById('medusa_player_body').replaceWith(newTBody(rowsIndexed))
    }
}

function createIndex(start, total, step, rows) {
    const maxVisible = Math.min(step, total - start)
    return rows.map((x, i) => {
	if (i < start) {
	    x.hidden = true
	    return x
	} else if (i < start + maxVisible) {
	    x.hidden = false
	    return x
	} else {
	    x.hidden = true
	    return x
	}
    })
}

function newTBody(rows) {
    const newTBodyO = document.createElement('tbody')
    newTBodyO.id = "medusa_player_body"
    rows.forEach((x) => newTBodyO.appendChild(x))
    return newTBodyO
}

function rowHidden(row) {
    const filters = [
	filter_player,
	filter_alliance,
	filter_min_population,
	filter_max_population,
	filter_min_village,
	filter_max_village,
	filter_distance,
	filter_min_confidence,
	filter_max_confidence,
	filter_yesterday_inactive,
	filter_today_inactive
    ]

    let result = undefined
    for (let f of filters) {
	result = f(row)
	if (result[1] == true) {
	    return result
	}
	}
    return result
}



function col(columnName) {
    return [
	"Name",
	"Alliance",
	"Population",
	"Villages",
	"Mass",
	"Distance",
	"InactiveYesterday",
	"InactiveToday",
	"Probability",
	"Model"
    ].findIndex((name) => name === columnName)
}

function hideRow(row, bool) {
    if (bool) {
	row.hidden = true
	return [row, true]
    } else {
	row.hidden = false
	return [row, false]
    }
}

function filter_player(row) {
    const player_filter = document.getElementById('player_filter').value.toLowerCase();
    const v = row.children[col("Name")].textContent.toLowerCase()

    if (player_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, !(v.includes(player_filter)))
}


function filter_alliance(row) {
    const alliance_filter = document.getElementById('alliance_filter').value.toLowerCase();
    const v = row.children[col("Alliance")].textContent.toLowerCase()

    if (alliance_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, !(v.includes(alliance_filter)))
}

function filter_min_population(row) {
    const population_min_filter = document.getElementById('population_min_filter').value;
    const v = parseInt(row.children[col("Population")].textContent.toLowerCase())

    if (population_min_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, v < parseInt(population_min_filter))
}

function filter_max_population(row) {
    const population_max_filter = document.getElementById('population_max_filter').value;
    const v = parseInt(row.children[col("Population")].textContent.toLowerCase())

    if (population_min_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, v > parseInt(population_max_filter))
}


function filter_min_village(row) {
    const village_min_filter = document.getElementById('village_min_filter').value;
    const v = parseInt(row.children[col("Villages")].textContent.toLowerCase())

    if (village_min_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, v < parseInt(village_min_filter))
}

function filter_max_village(row) {
    const village_max_filter = document.getElementById('village_max_filter').value;
    const v = parseInt(row.children[col("Villages")].textContent.toLowerCase())

    if (village_max_filter == "") {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, v > parseInt(village_max_filter))
}

function filter_min_confidence(row) {
    const confidence_min_filter = document.getElementById('min_confidence_filter').value;
    const v = parseFloat(row.children[col("Probability")].textContent.toLowerCase())

    if (confidence_min_filter == "") {
	row.hidden = false
	return [row, false]
    }

    const diff = Math.abs(v - 0.5)
    return hideRow(row, diff < parseFloat(confidence_min_filter))
}

function filter_max_confidence(row) {
    const confidence_max_filter = document.getElementById('max_confidence_filter').value;
    const v = parseFloat(row.children[col("Probability")].textContent.toLowerCase())

    if (confidence_max_filter == "") {
	row.hidden = false
	return [row, false]
    }

    const diff = Math.abs(v - 0.5)
    return hideRow(row, diff > parseFloat(confidence_max_filter))
}

function filter_yesterday_inactive(row) {
    const yesterday_filter = Array.from(document.getElementById('yesterday_inactive').selectedOptions).map((x) => x.value) 
    const v = row.children[col("InactiveYesterday")].textContent

    if (yesterday_filter == []) {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, !(yesterday_filter.includes(v)))
}

function filter_today_inactive(row) {
    const today_filter = Array.from(document.getElementById('today_inactive').selectedOptions).map((x) => x.value) 
    const v = row.children[col("InactiveToday")].textContent

    if (today_filter == []) {
	row.hidden = false
	return [row, false]
    }
    return hideRow(row, !(today_filter.includes(v)))
}

function filter_distance(row) {
    const distance_point = document.getElementById('position_filter').value
    const distance_filter = document.getElementById('max_distance_filter').value
    const [x1, y1] = parsePoint(row.children[col("Mass")].textContent)

    if (distance_filter === "" || distance_point === "") {
	row.hidden = false
	return [row, false]
    }

    const v = parsePoint(distance_point)
    if (v.map(Number.isNaN).includes(true)) {
	row.hidden = false
	return [row, false]
    }

    const [x2, y2] = v
    const dist = distance401(x1, y1, x2, y2)

    const bool = dist > parseFloat(distance_filter)
    if (bool === false) {
	row.children[col("Distance")].textContent = Math.round(dist * 10) / 10
    }

    return hideRow(row, bool)

}



function parsePoint(pointString) {
    //pointString.matchAll(/-?\d+/g)
    return pointString.substring(1, pointString.length -1).split('|', 2).map(parseFloat)
}


function distance401(x1, y1, x2, y2) {
    return distance(401.0, 401.0, x1, y1, x2, y2)
}

function distance(width, height, x1, y1, x2, y2) {
    const diff_x = Math.abs(x1 - x2)
    const diff_y = Math.abs(y1 - y2)
    return Math.sqrt(Math.pow(Math.min(diff_x, width - diff_x), 2) + Math.pow(Math.min(diff_y, width - diff_y), 2))
}
