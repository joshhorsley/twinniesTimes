export function toggleNav() {
    document.getElementById("sidebar").classList.toggle("hidden");
}

export function removeNav() {
    document.getElementById("sidebar").classList.add("hidden");
}

export function addNav() {
    document.getElementById("sidebar").classList.remove("hidden");
}

