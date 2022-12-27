const pos = document.getElementById('reference_point');
const apply_filters = document.getElementById("apply_filters");

apply_filters.addEventListener('click', applyFilters);
// alliance_filter.addEventListener('input', updateFilter);
// player_filter.addEventListener('input', updateFilter);
//pos.addEventListener('input', updateValue);

function updateValue(e) {
  log.textContent = e.target.value;
}

function applyFilters(e) {
    const newRows = Array.from(document.getElementById('medusa_player_body').rows)
	  .map(rowHidden)
	  .sort((tuple1, tuple2) => tuple1[1] > tuple2[1])

    const newTBody = document.createElement('tbody')
    newTBody.id = "medusa_player_body"
    newRows.forEach((tuple) => newTBody.appendChild(tuple[0]))
    document.getElementById('medusa_player_body').replaceWith(newTBody)

    const details_filter = document.getElementById("details_filters");
    details_filter.open = false

}

function rowHidden(row) {
    const filters = [
	filter_player,
	filter_alliance,
	filter_min_population,
	filter_max_population,
	filter_min_village,
	filter_max_village,
	filter_min_confidence,
	filter_max_confidence
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
