import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import membersAllFlat from "./data/membersListFlat.json"
import membersAllHeirarchy from "./data/memberListHierarchy.json"

// export async function getMembers(query) {
//   let members = membersAllFlat;

//   if (query) {
//     members = matchSorter(membersAllFlat, query, { keys: ["label", "value"] });
//   }
//   return members.sort(sortBy("last", "createdAt"));
// }

export async function getMembers(query) {
  let members = structuredClone(membersAllHeirarchy);

  if (query) {
    membersAllHeirarchy.forEach(function(item, index) { members[index].members = matchSorter(item.members, query, {keys: ["name_display", "id_member"]})});
  }
  return members;
}

export async function getMember(value) {

  if (membersAllFlat.filter((member) => member.value == value).length == 0) {
    throw new Response("", {
      status: 404,
      statusText: "Member not found"
    })
  }

  const response = await fetch('/data/members/' + value + '.json',{
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  })

  const memberData = await response.json();

  return memberData[0] ?? null;
}

export async function memberLoader({ params }) {
  const member = await getMember(params.memberId);

  if(!member) {
      throw new Response("", {
          status: 404,
          statusText: "Member not found"
      })
  }
  return { member };
}
