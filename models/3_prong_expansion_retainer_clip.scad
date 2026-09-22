$fn = 96;

head_outer_d = 13.5;
head_height = 9.0;
head_wall = 1.7;
head_draft_per_side = 0.22;
head_top_round = 0.8;
slot_count = 6;
slot_width = 1.6;
slot_top_width = 1.25;
slot_bottom_offset = 1.2;
slot_top_offset = 0.5;
slot_radial_inset = 0.3;
slot_radial_depth = 1.6;
slot_corner_round = 0.28;

flange_outer_d = 18.5;
flange_height = 3.5;
flange_edge_radius = 0.5;

prong_count = 3;
prong_width = 2.8;
prong_thickness = 2.0;
prong_length = 16.5;
prong_center_radius = 3.2;
hook_extension = 2.5;
hook_height = 2.2;
hook_tip_width_scale = 0.92;
hook_tip_height_scale = 0.78;
hook_tip_shift = 0.15;
edge_round = 0.35;
gusset_height = 3.8;
gusset_depth = 3.8;
gusset_corner_round = 0.35;
center_nub_d = 2.2;
center_nub_length = 1.8;

boss_d = 2.0;
boss_height = 2.4;
boss_tip_d = 1.4;
boss_recess_d = 1.0;
boss_recess_depth = 0.7;
boss_top_overlap = 0.25;
rib_thickness = 0.9;

head_inner_draft_factor = 0.7;
head_floor_clearance = 0.5;
head_cavity_cap_offset = 1.1;
head_cavity_cap_sphere_pad = 0.2;
head_cavity_cap_cylinder_h = 2.2;
head_cavity_cap_cylinder_pad = 0.4;
rib_root_overlap = 0.1;
rib_shell_overlap = 0.2;
rib_top_clearance = 1.2;
rib_base_offset = 0.5;
prong_shaft_overlap = 0.3;
relief_start_overlap = 0.05;
boolean_epsilon = 0.02;

module rounded_rect_2d(size, radius) {
    safe_radius = min(max(radius, 0), min(size[0], size[1]) / 2);
    if (safe_radius <= 0) {
        square(size, center = true);
    } else {
        hull() {
            for (x = [-1, 1]) {
                for (y = [-1, 1]) {
                    translate([
                        x * (size[0] / 2 - safe_radius),
                        y * (size[1] / 2 - safe_radius)
                    ])
                        circle(r = safe_radius);
                }
            }
        }
    }
}

module rounded_prism(size, radius) {
    linear_extrude(height = size[2])
        rounded_rect_2d([size[0], size[1]], radius);
}

module rounded_polygon_2d(points, radius) {
    if (radius <= 0) {
        polygon(points = points);
    } else {
        offset(r = radius)
            offset(delta = -radius)
                polygon(points = points);
    }
}

module flange() {
    flange_mid_height = max(flange_height - 2 * flange_edge_radius, boolean_epsilon);
    union() {
        translate([0, 0, flange_edge_radius])
            cylinder(h = flange_mid_height, d = flange_outer_d);
        cylinder(h = flange_edge_radius, d1 = flange_outer_d - 2 * flange_edge_radius, d2 = flange_outer_d);
        translate([0, 0, flange_height - flange_edge_radius])
            cylinder(h = flange_edge_radius, d1 = flange_outer_d, d2 = flange_outer_d - 2 * flange_edge_radius);
    }
}

module head_outer() {
    head_straight_height = max(head_height - head_top_round, boolean_epsilon);
    union() {
        translate([0, 0, flange_height])
            cylinder(
                h = head_straight_height,
                r1 = head_outer_d / 2 + head_draft_per_side,
                r2 = head_outer_d / 2
            );
        translate([0, 0, flange_height + head_height - head_top_round])
            intersection() {
                sphere(r = head_outer_d / 2);
                cylinder(h = head_top_round * 2, r = head_outer_d / 2 + 0.2);
            }
    }
}

module head_cavity() {
    inner_bottom_r = max(head_outer_d / 2 - head_wall, boolean_epsilon);
    inner_top_r = max(inner_bottom_r - head_draft_per_side * head_inner_draft_factor, boolean_epsilon);
    cavity_height = max(head_height - head_wall - head_floor_clearance, boolean_epsilon);
    cap_base_z = max(cavity_height - head_cavity_cap_offset, 0);

    translate([0, 0, flange_height - boolean_epsilon / 2])
        union() {
            cylinder(
                h = cavity_height,
                r1 = inner_bottom_r,
                r2 = inner_top_r
            );
            translate([0, 0, cap_base_z])
                intersection() {
                    sphere(r = inner_top_r + head_cavity_cap_sphere_pad);
                    cylinder(h = head_cavity_cap_cylinder_h, r = inner_top_r + head_cavity_cap_cylinder_pad);
                }
        }
}

module head_slots() {
    slot_height = max(head_height - slot_bottom_offset - slot_top_offset, boolean_epsilon);
    bottom_slot_depth = head_wall + slot_radial_depth;
    top_slot_depth = max(bottom_slot_depth - 0.22, boolean_epsilon);
    slot_top_z = flange_height + slot_bottom_offset + slot_height - boolean_epsilon;
    slot_round = max(0, min(
        slot_corner_round,
        slot_width / 2 - boolean_epsilon,
        slot_top_width / 2 - boolean_epsilon,
        bottom_slot_depth / 2 - boolean_epsilon,
        top_slot_depth / 2 - boolean_epsilon
    ));
    for (i = [0 : slot_count - 1]) {
        rotate([0, 0, i * 360 / slot_count])
            hull() {
                translate([head_outer_d / 2 - head_wall - slot_radial_inset, 0, flange_height + slot_bottom_offset])
                    rounded_prism([bottom_slot_depth, slot_width, boolean_epsilon], slot_round);
                translate([head_outer_d / 2 - head_wall - slot_radial_inset + 0.18, 0, slot_top_z])
                    rounded_prism([top_slot_depth, slot_top_width, boolean_epsilon], slot_round);
            }
    }
}

module interior_ribs() {
    inner_bottom_r = head_outer_d / 2 - head_wall;
    rib_start = boss_d / 2 - rib_root_overlap;
    rib_length = max(inner_bottom_r - rib_start + rib_shell_overlap, boolean_epsilon);
    rib_height = max(head_height - head_wall - rib_top_clearance, boolean_epsilon);

    for (i = [0 : slot_count - 1]) {
        rotate([0, 0, i * 360 / slot_count])
            translate([rib_start, -rib_thickness / 2, flange_height + rib_base_offset])
                cube([rib_length, rib_thickness, rib_height]);
    }
}

module inner_boss() {
    boss_tip_z = flange_height + head_height - head_wall - boss_height;
    boss_tip_center_z = boss_tip_z + boss_tip_d / 2;
    boss_top_center_z = boss_tip_z + boss_height - boss_d / 2 + boss_top_overlap;

    difference() {
        union() {
            translate([0, 0, boss_tip_center_z])
                sphere(d = boss_tip_d);
            translate([0, 0, boss_tip_center_z])
                cylinder(h = boss_top_center_z - boss_tip_center_z, d = boss_d);
            translate([0, 0, boss_top_center_z])
                sphere(d = boss_d);
        }
        translate([0, 0, boss_tip_z - boolean_epsilon])
            cylinder(h = boss_recess_depth + boolean_epsilon * 2, d = boss_recess_d);
    }
}

module body_shell() {
    difference() {
        union() {
            flange();
            head_outer();
        }
        difference() {
            head_cavity();
            union() {
                interior_ribs();
                inner_boss();
            }
        }
        head_slots();
    }
}

module prong() {
    hook_tip_height = max(hook_height * hook_tip_height_scale, boolean_epsilon);
    difference() {
        union() {
            translate([prong_center_radius, 0, -prong_length])
                rounded_prism([prong_thickness, prong_width, prong_length + prong_shaft_overlap], edge_round);

            hull() {
                translate([prong_center_radius + hook_extension * 0.22, 0, -prong_length])
                    rounded_prism([prong_thickness + hook_extension * 0.56, prong_width, hook_height], edge_round);
                translate([prong_center_radius + hook_extension / 2, 0, -prong_length + hook_height * hook_tip_shift])
                    rounded_prism([prong_thickness, prong_width * hook_tip_width_scale, hook_tip_height], edge_round);
            }

            translate([prong_center_radius - prong_thickness / 2, 0, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = prong_width, center = true)
                        rounded_polygon_2d([
                            [0, 0],
                            [gusset_depth, 0],
                            [gusset_depth, -gusset_height],
                            [0, -gusset_height * 0.45]
                        ], gusset_corner_round);
        }

        translate([0, 0, -prong_length + hook_height - relief_start_overlap])
            cylinder(h = prong_length - hook_height + prong_shaft_overlap + relief_start_overlap, d = prong_center_radius * 2 - prong_thickness);
    }
}

module stem() {
    nub_radius = center_nub_d / 2;
    nub_cylinder_height = max(center_nub_length - nub_radius, 0);
    nub_base_z = -center_nub_length + boolean_epsilon;
    union() {
        for (i = [0 : prong_count - 1]) {
            rotate([0, 0, i * 360 / prong_count])
                prong();
        }

        translate([0, 0, nub_base_z])
            if (nub_cylinder_height > 0) {
                union() {
                    cylinder(h = nub_cylinder_height, d = center_nub_d);
                    translate([0, 0, nub_cylinder_height])
                        sphere(d = center_nub_d);
                }
            } else {
                translate([0, 0, center_nub_length / 2])
                    scale([1, 1, max(center_nub_length / center_nub_d, boolean_epsilon)])
                        sphere(d = center_nub_d);
            }
    }
}

union() {
    body_shell();
    stem();
}
