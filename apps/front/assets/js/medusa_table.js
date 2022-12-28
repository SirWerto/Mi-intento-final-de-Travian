const server_search = document.getElementById("server_search");

server_search.addEventListener('input', searchServers);

function searchServers(e) {
    const v = server_search.value.toLowerCase()

    if (v == "") {
	return ""
    }

    const f = (x) => {
	const server = x.children[0].textContent.trim().toLowerCase()
	const [s1, s2] = truncate(v, server)
	return [x, hamming(s1, s2)]
    }

    const newRows = Array.from(document.getElementById('medusa_tbody').rows)
     	  .map(f)
     	  .sort((tuple1, tuple2) => tuple1[1] > tuple2[1])

    console.log(newRows)

    const newTBody = document.createElement('tbody')
    newTBody.id = "medusa_tbody"
    newRows.forEach((x) => newTBody.appendChild(x[0]))
    console.log(newTBody)
    document.getElementById('medusa_tbody').replaceWith(newTBody)
}




function truncate(string1, string2) {
    diff = string1.length - string2.length

    if (diff === 0) {
	return [string1, string2]
    } else if (diff > 0) {
	return [string1.slice(0, string2.length), string2]
    } else {
	return [string1, string2.slice(0, string1.length)]
    }
}
function hamming(string1, string2) {
    if (string1.length !== string2.length) {
	throw "strings have different lengths";
    } else {
	return string1.split('').reduce((acc, x, i) => x === string2.charAt(i)? acc : acc+1, 0)
    }
}
