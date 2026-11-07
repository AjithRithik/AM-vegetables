# Admin panel (`/staff`)

Log in with your **mobile number and password**. The panel works on phone and desktop.

## Products (owner and vendor)
- Pick the location at the top (sidebar on desktop). Everything on this page is for that location.
- Each row is a product with its price boxes. Type a price and press **Enter** or tap away: it saves
  immediately and the box flashes green. Enter jumps to the next price.
- **Selling** switch: is this product sold at this location? **In stock** switch: greyed out for customers when off.
  The star features it on the app's home screen.
- A product with no price at a location is hidden from customers there. The yellow bar shows how many still need one,
  and **Needs price** filters to them.
- **Tools**: copy prices from another location, or export / import a CSV to fill prices in Excel.

## Add / edit a product (owner)
**Add product** (or the pencil on a row) opens one form: photo link, English and Tamil name, category, how it is sold,
which locations sell it, and every size with its price **per location side by side**. Tap the quick buttons
(250 g, 500 g, 1 kg ...) to add sizes. Vendors open the same form but can only change availability and prices
for their own locations.

## Orders (owner and vendor)
Orders placed in the app appear here, newest first, for the right location. The number on the **Orders** tab
is how many are waiting; a pop-up and a beep appear when a new one arrives (the panel checks every 30 seconds,
browsers only play the beep after the page has been clicked once). Buttons: **Confirm**, **Mark delivered**,
**Cancel**, **WhatsApp** the customer, **Call**. Prices on an order are the ones in force when it was placed.
The owner sees all locations; a vendor sees only theirs.

## Locations (owner)
One card per location: address, WhatsApp number (orders from that location are sent to it), hours, delivery pincodes,
open/closed and **Live in app**. **Add location** starts empty: enable products and set prices afterwards (or copy
another location's product list while creating). Your own number under *Owner copy of orders* is stored for a future
automatic copy; today you see every order in this panel.

## Team (owner)
**Add vendor**: mobile number, name, a password (a strong one is suggested) and the locations they manage.
After saving you get a screen with the login details to copy or send on WhatsApp. To reset a password, edit the
vendor and type a new one. Vendors can edit only their own locations.

## Notes
- If saving fails with a permission message, the account probably is not assigned to that location (Team tab).
- Product photos are Cloudinary links. Paste the image URL in the product form.
- Change the owner password in Supabase: Authentication -> Users.
