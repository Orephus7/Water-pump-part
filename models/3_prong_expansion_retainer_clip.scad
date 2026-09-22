$fn = 96;

head_outer_d = 13.5;
head_height = 9.0;
head_wall = 1.7;
head_draft_per_side = 0.22;
head_top_round = 0.8;
slot_count = 6;
slot_width = 1.6;
slot_bottom_offset = 1.2;
slot_top_offset = 0.5;

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
edge_round = 0.35;
gusset_height = 3.8;
gusset_depth = 3.8;
center_nub_d = 2.2;
center_nub_length = 1.8;

boss_d = 2.0;
boss_height = 2.4;
boss_tip_d = 1.4;
boss_recess_d = 2.0;
boss_recess_depth = 0.7;
rib_thickness = 0.9;

module rounded_rect_2d(size, radius) {
    offset(r = radius)
        square([size[0] - 2 * radius, size[1] - 2 * radius], center = true);
}

module rounded_prism(size, radius) {
    linear_extrude(height = size[2])
        rounded_rect_2d([size[0], size[1]], radius);
}

module flange() {
    union() {
        translate([0, 0, flange_edge_radius])
            cylinder(h = flange_height - 2 * flange_edge_radius, d = flange_outer_d);
        cylinder(h = flange_edge_radius, d1 = flange_outer_d - 2 * flange_edge_radius, d2 = flange_outer_d);
        translate([0, 0, flange_height - flange_edge_radius])
            cylinder(h = flange_edge_radius, d1 = flange_outer_d, d2 = flange_outer_d - 2 * flange_edge_radius);
    }
}

module head_outer() {
    union() {
        translate([0, 0, flange_height])
            cylinder(
                h = head_height - head_top_round,
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
    inner_bottom_r = head_outer_d / 2 - head_wall;
    inner_top_r = inner_bottom_r - head_draft_per_side * 0.7;
    cavity_height = head_height - head_wall - 0.5;

    translate([0, 0, flange_height - 0.01])
        union() {
            cylinder(
                h = cavity_height,
                r1 = inner_bottom_r,
                r2 = inner_top_r
            );
            translate([0, 0, cavity_height - 1.1])
                intersection() {
                    sphere(r = inner_top_r + 0.2);
                    cylinder(h = 2.2, r = inner_top_r + 0.4);
                }
        }
}

module head_slots() {
    slot_height = head_height - slot_bottom_offset - slot_top_offset;
    for (i = [0 : slot_count - 1]) {
        rotate([0, 0, i * 360 / slot_count])
            translate([head_outer_d / 2 - head_wall - 0.3, -slot_width / 2, flange_height + slot_bottom_offset])
                cube([head_wall + 1.6, slot_width, slot_height]);
    }
}

module interior_ribs() {
    inner_bottom_r = head_outer_d / 2 - head_wall;
    rib_start = boss_d / 2 - 0.1;
    rib_length = inner_bottom_r - rib_start + 0.2;
    rib_height = head_height - head_wall - 1.2;

    for (i = [0 : slot_count - 1]) {
        rotate([0, 0, i * 360 / slot_count])
            translate([rib_start, -rib_thickness / 2, flange_height + 0.5])
                cube([rib_length, rib_thickness, rib_height]);
    }
}

module inner_boss() {
    boss_tip_z = flange_height + head_height - head_wall - boss_height;
    boss_tip_center_z = boss_tip_z + boss_tip_d / 2;
    boss_top_center_z = boss_tip_z + boss_height - boss_d / 2 + 0.25;

    difference() {
        union() {
            translate([0, 0, boss_tip_center_z])
                sphere(d = boss_tip_d);
            translate([0, 0, boss_tip_center_z])
                cylinder(h = boss_top_center_z - boss_tip_center_z, d = boss_d);
            translate([0, 0, boss_top_center_z])
                sphere(d = boss_d);
        }
        translate([0, 0, boss_tip_z - 0.02])
            cylinder(h = boss_recess_depth + 0.04, d = boss_recess_d);
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
    difference() {
        union() {
            translate([prong_center_radius, 0, -prong_length])
                rounded_prism([prong_thickness, prong_width, prong_length + 0.3], edge_round);

            translate([prong_center_radius, 0, -prong_length])
                rounded_prism([prong_thickness + hook_extension, prong_width, hook_height], edge_round);

            translate([prong_center_radius - prong_thickness / 2, 0, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = prong_width, center = true)
                        polygon(points = [
                            [0, 0],
                            [gusset_depth, 0],
                            [gusset_depth, -gusset_height]
                        ]);
        }

        translate([0, 0, -prong_length - 0.01])
            cylinder(h = hook_height + 0.02, d = prong_center_radius * 2 - prong_thickness);
    }
}

module stem() {
    union() {
        for (i = [0 : prong_count - 1]) {
            rotate([0, 0, i * 360 / prong_count])
                prong();
        }

        translate([0, 0, -center_nub_length])
            union() {
                cylinder(h = center_nub_length - center_nub_d / 4, d = center_nub_d);
                translate([0, 0, center_nub_length - center_nub_d / 4])
                    sphere(d = center_nub_d);
            }
    }
}

union() {
    body_shell();
    stem();
}
