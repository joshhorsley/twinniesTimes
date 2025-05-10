import { matchSorter } from "match-sorter";
import sortBy from "sort-by";

import contactsAll from "./data/membersList.json"

export async function getContacts(query) {
  let contacts = contactsAll;

  if (query) {
    contacts = matchSorter(contactsAll, query, { keys: ["label", "value"] });
  }
  return contacts.sort(sortBy("last", "createdAt"));
}


export async function getContact(value) {

  if (contactsAll.filter((contact) => contact.value == value).length == 0) {
    throw new Response("", {
      status: 404,
      statusText: "Contact not found"
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
