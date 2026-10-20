/// Launch focus: only these catalog slugs can be booked end-to-end.
/// Everything else renders with a "coming soon" badge until its partner
/// coverage and pricing go live. Single source for the landing page, the
/// customer home grid, and the booking flow.
const liveBookingSlugs = {'water-purifier-repair'};

bool isBookableCategory(String? slug) =>
    liveBookingSlugs.contains((slug ?? '').toLowerCase());
